use strict;
package WWW::Search::Scraper::Request;


sub new {
    my ($self, $query, $options_ref) = @_;
    $self = bless {}, $self;
    
    $self->{'_state'}   = 0;  # Current state of request object -
                              #     0 - query has not yet been set.
                              #     1 - query is set, not yet "prepared" to "fields"
                              #     2 - fields have been set.
    $self->{'_query'}   = {}; # The basic, canonical, query (SQL WHERE clause-ish)
    $self->{'_fields'}  = {}; # That query broken up into field (SQL column) relations
                              # leading "op" character - '=' equal, '#' not equal.
    $self->{'_engines'} = {}; # Special messages to each type of Scraper module.
    
    if ( $query ) {
        $self->query($query); # This should be translated from generic query to native query.
        $self->{'_state'} = 1;
    }
    if (defined($options_ref)) {
    	# Copy in new options.
    	foreach (keys %$options_ref) {
    	    $self->field($_, $options_ref->{$_}) if defined $options_ref->{$_};
    	};
    };
    return $self;
}


# A generalize get/set method for object attributes.
sub _attr {
    my ($self, $attr, $value) = @_;
    my $rtn = $self->{$attr};
    $self->{$attr} = $value if defined $value;
    if ( wantarray ) {
        return $rtn if 'ARRAY' eq ref $rtn;
        return [$rtn];
    }
    return $rtn;
}
sub query          { $_[0]->_attr('_query', $_[1]) }
sub debug          { $_[0]->_attr('_debug', $_[1]) }

# A generalize get/set method for "field" attributes.
sub field {
    my ($self, $field, $value) = @_;
    my $rtn = $self->{'_fields'}->{$field};
    $self->{'_fields'}->{$field} = $value if defined $value;
#print "$field:'$self->{'_fields'}->{$field}'\n" if defined $value;    
    return $rtn;
}
# Return the fields array (which is actually a hashref, v1.00).
sub fields { $_[0]->{'_fields'} }



# Parse the SQL WHERE-ish clause in '_query' into '_fields' array.
sub prepare {
    my ($self) = @_;

    # We don't do this process in v1.00; we rely on the user to have set the fields array.
    $self->{'_state'} = 2;
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
by Glenn Wood, <glenwood@alumni.caltech.edu>.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut



