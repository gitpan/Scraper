use strict;
package WWW::Search::Scraper::Request;

{ package WWW::Search::Scraper::Request::_struct_;
use Class::Struct;
    struct ( 
                 '_state'   => '$'
                ,'_fields'  => '$'
                ,'_engines' => '%'
                ,'_native_query' => '$'     # native_query for legacy (WWW::Search) style requests.
                ,'_native_options' => '$'   # native_options for legacy (WWW::Search) style requests.
                ,'_postSelect' => '%'
                ,'_Scraper_debug'  => '$'
           );
}
use base qw(WWW::Search::Scraper::Request::_struct_);

sub FieldTitles {
    return {  };
}

sub new {
    my $self = new WWW::Search::Scraper::Request::_struct_;
    bless $self, shift;
    $self->_init(@_);
}

sub _init {
    my ($self, $query, $options_ref) = @_;

    $self->_native_query($query);
    $self->_native_options($options_ref) if ref $options_ref eq 'HASH';

    return $self;
}


# A generalize get/set method for "field" attributes.
sub field {
    my ($self, $field, $value) = @_;
    my $rtn = $self->_fields($field);
    $self->{'_fields'}->{$field} = $value if defined $value;
#print "$field:'$self->{'_fields'}->{$field}'\n" if defined $value;    
    return $rtn;
}
# Return the fields array (which is actually a hashref, v1.00).
sub fields { $_[0]->{'_fields'} }



### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 
# Prepare the query and options of the Scraper module, based on the given request.
# Parse the SQL WHERE-ish clause in '_query' into '_fields' array.
#
# We don't do this process in v1.00; we rely on the user to have set the fields array.
sub prepare {
    my ($self, $scraper) = @_;

    # Move the field values from $self into $scraper, translating
    # field names to option names according to $scraper->fieldTranslations.
    # fieldTranlations{'*'} eq '*' - clone the name
    # fieldTranlations{'*'} ne '*' - drop that field.
    my $fieldTitles = $self->FieldTitles;
    my $options_ref = $scraper->{'native_options'};
    $options_ref = {} unless ( $options_ref );

    # This gets our defaults into these values, if the Scraper engine is not fully defined.
    my $scraperQuery = $scraper->scraperQuery();
    $scraper->queryDefaults($scraperQuery->{'nativeDefaults'}) unless $scraper->queryDefaults();
    $scraper->fieldTranslations($scraperQuery->{'fieldTranslations'}) unless $scraper->fieldTranslations();
    
    # Set nativeQuery field value first; it may be overwritten by FieldTranslations later, which is what we'd want.
    $options_ref->{$scraperQuery->{'nativeQuery'}} = $self->_native_query() if $scraperQuery->{'nativeQuery'};
    
    $scraper->cookie_jar(HTTP::Cookies->new()) if $scraperQuery->{'cookies'}; 

    my $fieldTranslationsTable = $scraper->fieldTranslations();
    my $fieldTranslations = $fieldTranslationsTable->{'*'}; # We'll do this until context sensitive work is done - gdw.2001.08.18
    my $fieldTranslation;

    # Translate all the fields whose titles are listed by this Request object.
    for ( keys %$fieldTitles ) {
        # Find what option we'll be translating to, or default (by cloning).
        $fieldTranslation = $$fieldTranslations{$_};
        next if defined $fieldTranslation and $fieldTranslation eq '';
        unless ( $fieldTranslation ) {
            if ($$fieldTranslations{'*'} eq '*' ) {
                $fieldTranslation = $_;
            } else {
                next;
            }
        }
        # 'fieldTranslation' may be a string naming the option, or 
        # a subroutine tranforming the field into a (nam,val) pair,
        # or a FieldTranslation object.
        if ( 'CODE' eq ref $fieldTranslation ) {
            my ($nam, $val, $postSelect) = &$fieldTranslation($scraper, $self, $self->$_());
            next unless ( $nam );
            $options_ref->{$nam} = $val;
            # Stuff the postSelect criteria for checking later.
            $self->_postSelect($nam, $postSelect) if defined $postSelect;
        } elsif ( ref $fieldTranslation ) { # We assume any other ref is an object of some sort.
            my $nam = $fieldTranslation->translate($scraper, $self, $self->$_());
            for ( keys %$nam ) {
                $options_ref->{$_} = $$nam{$_};
            }
        }
        else {
            $options_ref->{$fieldTranslation} = $self->$_();
        }
    }
    $scraper->{'native_options'} = $options_ref;
}

### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 
# Given a candidate hit, do post-selection.
# Return 1 to keep this hit, 0 to cast it away.
sub postSelect {
#    my ($rqst, $scraper, $rslt, $alreadyDone) = @_;
    # The Request module does a postSelect for Scraper modules too lazy to do their own.
    return 1;
}

# Return true if the string $which is in the string, or the array referenced by, $alreadyDone.
sub alreadyDone {
    my ($self, $which, $alreadyDone) = @_;
    return 0 unless $alreadyDone;
    my $alD = $alreadyDone;
    $alD = [$alreadyDone] unless 'ARRAY' eq ref $alD;
    for ( @$alD ) {
        return 1 if ( $_ eq $which );
    }
    return 0;
}

1;

__END__

=head1 NAME

WWW::Search::Scraper::Request - Canonical form for Scraper requests

=head1 SYNOPSIS

    use WWW::Search::Scraper::Request;

    $request = new WWW::Search::Scraper::Request( $query );

    $scraper = new WWW::Search::Scraper( $engine );
    $scraper->request($request);
    while ( $result = $scraper->next_response() ) {
        # Consume your $results !
    }

=head1 DESCRIPTION

In this version 1.00, the user must set all field values via $rqst->field(name, value).
This base class does not have any fields assigned to it, except the implicit "query" field,
which you will set at the new() method, or via the query() method.

This is the minimal condition required to pass it to the Scaper module's prepare() method.
(Later, we anticipate setting the SQL WHERE-ish query(); then prepare() would translate that via field(), first.)

=head1 METHODS

=head2 query

Get/Set the query string. You may also set the query string in the new() method.

=head2 postSelect

C<postSelect()> is a callback function that may be called by the Scraper module to help it 
decide if the response it has received will actually qualify against this request. 
C<postSelect()> should return true if the response matches the request, false if not.

The parameters C<postSelect()> will receive are

=over 8

=item $request

A reference to itself, of course.

=item $scraper

A reference to the Scraper module under which all of this is happening.
You probably won't need this, but there it is.

=item $response

The Scraper::Response object that is the actual response.
This is probably (or should be) an extension to a sub-class appropriate to your Scraper::Request sub-class.

=item $alreadyDone

The Scraper module will tell you which fields, by name, that it has already has (or will) handle on it's own.
This parameter may be a string holding a field name, or a reference to an array of field names.

C<Scraper::Request> contains a method for helping you vector on $alreadyDone. 
The method 

    $request->alreadyDone('fieldName', $alreadyDone)

will return true if the field 'fieldName' is in $alreadyDone.

=back

=head2 debug

The C<debug> method sets the debug tracing level to the value of its first parameter.

=head1 TRANSLATIONS

The Scraper modules that do table driven field translations (from canonical requests to native requests) will have
files included in their package representing the translation table in Storable format. The names of these files are
<ScraperModuleName>.<requestType>.<canonicalFieldName>. E.G., Brainpower.pm owns a translation table for the 'locations'
field of the canonical Request::Job module; it is named C<Brainpower.Job.locations> . 

The Scraper module will locate the translation file, when required, by searching the @INC path-search until it is found
(the same path-search Perl uses to locate Perl modules.)

=head2 set<fieldName>Translation()

The methods set<fieldName>Translations() can be used to help maintain these translation files. 
For instance, setLocationsTranslation('canonical', 'native') will establish a translation from 'canonical' to 'native'
for the 'locations' request field.

    setLocationsTranslation('CA-San Jose', 5);       # CA-San Jose => '5'
    setLocationsTranslation('CA-San Jose', [5,6]);   # CA-San Jose => '5' + '6'
    
If you have used this method to upgrade your translations, 
then a new upgrade of F<WWW::Search::Scraper> will probably over-write your tranlation file(s),
so watch out for that! Back up your translation files before upgrading F<WWW::Search::Scraper>!

=head1 AUTHOR

C<WWW::Search::Scraper::Request> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut



