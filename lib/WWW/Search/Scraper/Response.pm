package WWW::Search::Scraper::Response;

=head1 NAME

WWW::Search::Scraper::Response - Response class of generic scrapes.

=head1 SYNOPSIS

    use WWW::Search::Scraper('engineName');
    #
    my $scraper = new WWW::Search::Scraper('engineName');
    my $response = $scraper->Response();
    #
    my $field = $response->$fieldName();
    # or
    my $field = $scraper->Response->$fieldName();
    #
    # or, specify your own Response class.
    my $scraper = new WWW::Search::Scraper('engineName', 'responseClass');
    my $field = $scraper->Response->$fieldName();

=head1 DESCRIPTION

Scraper automatically generates a "Response" class for each scraper engine.
It does this by parsing the "scraperFrame" to identify all the field names fetched by the scraper.
It defines a get/set method for each of these fields, each named the same as the field name found in the "scraperFrame".

Optionally, you may write your own Response class and declare that as the Response class for your queries.
This is useful for defining a common Response class to a set of scraper engines (all auction sites, for instance).
See WWW::Search::Scraper::Response::Auction for an example of this type of Response class.

=head1 METHODS

=over 8

=item $fieldName

As mentioned, Response will automatically define get/set methods for each of the fields in the "scraperFrame".
For instance, for a field named "postDate", you can get the field value with 

    $response->postDate();

You may also set the value of the postDate, but that would be kind of silly, wouldn't it?

=item GetFieldNames

A reference to a hash is returned listing all the field names in this response.
The keys of the hash are the field names, while the values are 1, 2, or 3.
A value of 1 means the value comes from the result page;
2 means the value comes from the detail page;
3 means the value is in both pages.

=item SkipDetailPage

A well-constructed Response class (as Scraper auto-generates) implements a lazy-access method for each
of the fields that come from the detail page. 
This means the detail page is fetched only if you ask for that field value.
The SkipDetailPage() method controls whether the detail page will be fetched or not.
If you set it to 1, then the detail page is never fetched (detail dependent fields return undef).
Set to 2 to read the detail page on demand.
Set to 3 to read the detail page for fields that are only on the detail page,
and don't fetch the detail page, but return the results page value, for fields that appear on both pages.

SkipDetailPage defaults to 2.

=item ScrapeDetailPage

Forces the detail page to be read and scraped right now.

=item GetFieldValues

Returns all field values of the response in a hash table (by reference).
Like GetFieldNames(), the keys are the field names, but in this case the values are the field values of each field.

=item GetFieldTitles

Returns a reference to a hash table containing titles for each field (which might be different than the field names).

=back

=head1 AUTHOR

C<WWW::Search::Scraper::Response::Scraper> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

use strict;
use vars qw($VERSION @ISA);
@ISA = qw(WWW::SearchResult);
$VERSION = sprintf("%d.%02d", q$Revision: 1.11 $ =~ /(\d+)\.(\d+)/);
require WWW::SearchResult;
my %AlreadyDeclared;


sub fieldCapture {
    my ($scaffold) = @_;
    my @fields;
    my $next_scaffold;
SCAFFOLD: for my $scaffold ( @$scaffold ) {
        $next_scaffold = undef;
        
        my $tag = $$scaffold[0];
        if ( $tag =~ m/HIT|HIT\*/ )
        {
            my $resultType = $$scaffold[1];
            if ( 'ARRAY' eq ref $resultType ) {
                $next_scaffold = $resultType;
                $resultType = '';
            }
            else
            {
                $resultType = "::$resultType";
                $next_scaffold = $$scaffold[2];
                #$next_scaffold = $$scaffold[1] unless defined $next_scaffold;
                next SCAFFOLD;
            }
        }
        elsif ( $tag =~ m/HTML|TidyXML|TABLE|TR|DL|FORM|FOR/ )
        {
            my $i = 1;
            while ( $$scaffold[$i] and 'ARRAY' ne ref($$scaffold[$i]) ) { $i += 1; }
            $next_scaffold = $$scaffold[$i];
        }
        elsif ('BODY' eq $tag) { # 'BODY', 'x', 'y' , [[.]]
            if ( 'ARRAY' ne ref $$scaffold[3]  ) # if next_scaffold is an array ref, then we'll recurse (below)
            {
                push @fields, $$scaffold[3];
                next SCAFFOLD;
            } else {
                $next_scaffold = $$scaffold[3];
            }
        }
        elsif ( 'DATA' eq $tag )
        {
            next SCAFFOLD unless ( $$scaffold[1] and $$scaffold[2] ) ;
            push @fields, $$scaffold[3];
            next SCAFFOLD;
        }
    	elsif ( $tag =~ m/^(TABLE|TR|DL|FORM)$/ )
    	{
            $next_scaffold = $$scaffold[1];
            $next_scaffold = $$scaffold[2] unless ( 'ARRAY' eq ref $next_scaffold );
        }
    	elsif ( 'TAG' eq $tag )
        {
            #$tag = $$scaffold[1];
    		$next_scaffold = $$scaffold[2];
            if ( 'ARRAY' ne ref $next_scaffold  ) # if next_scaffold is an array ref, then we'll recurse (below)
            {
                push @fields, $next_scaffold if $next_scaffold;
                next SCAFFOLD;
            }
        }
    	elsif ( $tag =~ m/^(TD|DT|DD|DIV|RESIDUE)$/ )
        {
    		$next_scaffold = $$scaffold[1];
            if ( 'ARRAY' ne ref $next_scaffold  ) # if next_scaffold is an array ref, then we'll recurse (below)
            {
                push @fields, $next_scaffold if $next_scaffold;
                next SCAFFOLD;
            }
        }
        elsif ( 'A' eq $tag or 'AN' eq $tag ) 
        {
            #my $lbl = $$scaffold[1];
            push @fields, $$scaffold[1] if $$scaffold[1];
            push @fields, $$scaffold[2] if $$scaffold[2];
            next SCAFFOLD;
        }
        elsif ( 'REGEX' eq $tag or 'F' eq $tag ) 
        {
            my @ary = @$scaffold;
            shift @ary; shift @ary;
            map { push @fields, $_ if defined $_ } @ary;
            next SCAFFOLD;
        }
        elsif ( 'CALLBACK' eq $tag ) 
        {
            my @ary = @$scaffold;
            shift @ary; shift @ary; shift @ary; shift @ary;
            $next_scaffold = shift @ary;
            unless ( 'ARRAY' eq ref $next_scaffold ) {
                push @fields, $next_scaffold if ( defined $next_scaffold );
                next SCAFFOLD;
            }
        }
        elsif ( $tag eq 'XPath' )
        {
            $next_scaffold = $$scaffold[2];
            unless ( 'ARRAY' eq ref $next_scaffold ) {
                push @fields, $next_scaffold if ( defined $next_scaffold );
                next SCAFFOLD;
            }
        }
        push @fields, fieldCapture($next_scaffold) if $next_scaffold;
    }
    return @fields;
}


sub new { 
    my ($class, $SubClass, $scraperSearchResultsFrame, $scraperDetailFrame) = @_;

    my $self;
    $SubClass = "::$SubClass" if ( $SubClass );

    my (%subFields,$countSubFields);
    unless ( $AlreadyDeclared{$SubClass} ) {
        
        $subFields{'url'} = 1 if $SubClass eq '::Sherlock'; # Help Sherlock along.
        $subFields{'detail'} = 1 if $SubClass eq '::Sherlock'; # Help Sherlock along.
        
        # value of {'fieldName'} == 1 means field is from searchResultsFrame, only
        map { $subFields{$_} = 1 } fieldCapture($scraperSearchResultsFrame);

        # value of {'fieldName'} == 2 means field is from searchDetailFrame, only
        # value of {'fieldName'} == 3 means field is from searchResultsFrame and searchDetailFrame 
        if ( $scraperDetailFrame ) {
            my $i = 1;
            while ( 'ARRAY' ne ref $$scraperDetailFrame[$i] ) { $i += 1; }
            $scraperDetailFrame = ${$scraperDetailFrame}[$i];
            map { $subFields{$_} = (defined $subFields{$_})?3:2 } fieldCapture($scraperDetailFrame);
        }

        my $subFieldsStruct = join '\'=>\'@\',\'__', keys %subFields;
        die "No fields were found in the scraperFrames for WWW::Search::Scraper::Response$SubClass\n" unless keys %subFields;

        eval <<EOT;
{ package WWW::Search::Scraper::Response$SubClass\::_struct_;
use Class::Struct;
    struct ( 'WWW::Search::Scraper::Response$SubClass\::_struct_' => {
                 '_state'   => '\$'
                ,'_searchObject'  => '\$'
                ,'_fieldCount'  => '\$'
                ,'_fieldNames'  => '\$'
                ,'_skipDetailPage' => '\$'
                ,'_gotDetailPage'  => '\$'
                ,'_engines' => '\%'
                ,'_native_query' => '\$'
                ,'_native_options' => '\$'   # reference to hash of native_options.
                ,'_ScraperEngine'  => '\$'
                ,'_Scraper_debug'  => '\$'
# Now for the $SubClass specific members.
,'__$subFieldsStruct'=>'\@'
                }
           );
}

package WWW::Search::Scraper::Response$SubClass;
use WWW::Search::Scraper::Response;
use vars qw(\@ISA);
\@ISA = qw( WWW::Search::Scraper::Response$SubClass\::_struct_ WWW::Search::Scraper::Response );

        
1;
EOT
        die $@ if $@;
        $AlreadyDeclared{$SubClass} = [(keys %subFields)+11, \%subFields];
    }
    
    eval "\$self = new WWW::Search::Scraper::Response$SubClass;";
    die $@ if $@;
    
    $self->_fieldCount(${AlreadyDeclared{$SubClass}}[0]);
    $self->_fieldNames(${AlreadyDeclared{$SubClass}}[1]);

    # Build 'wantarray' context sensitive accessors for all fields
    # Build lazy-accessors for fields available from the Details page.
    my $fieldNames = $self->_fieldNames();
    my $accessors = '';
    for ( keys %$fieldNames ) {
        if ( $fieldNames->{$_} == 1 ) {
            $accessors .= <<EOT;
sub $_ {
    my \$slf = shift;
    my \$val = shift;
    if ( defined \$val ) {
        my \$ref = \$slf->__$_();
        if ( defined \$ref ) {
            push \@\$ref, \$val;
        } else {
            \$slf->__$_(1,\$val);
        }
    }
    if ( wantarray ) {
        return \@{\$slf->__$_()};
    } else {
        return \${\$slf->__$_()}[0];
    }
}
EOT
        }
        if ( $fieldNames->{$_} == 2 ) {
            $accessors .= <<EOT;
sub $_ {
    my \$slf = shift;
    my \$val = shift;
    \$slf->ScrapeDetailPage();
    if ( defined \$val ) {
        my \$ref = \$slf->__$_();
        if ( defined \$ref ) {
            push \@\$ref, \$val;
        } else {
            \$slf->__$_(1,\$val);
        }
    }
    if ( wantarray ) {
        return \@{\$slf->__$_()};
    } else {
        return \${\$slf->__$_()}[0];
    }
}
EOT
        }
        elsif ( $fieldNames->{$_} == 3 ) {
            $accessors .= <<EOT;
sub $_ {
    my \$slf = shift;
    my \$val = shift;
    \$slf->ScrapeDetailPage() if defined(\$slf->_skipDetailPage()) && \$slf->_skipDetailPage() != 3;
    if ( defined \$val ) {
        my \$ref = \$slf->__$_();
        if ( defined \$ref ) {
            push \@\$ref, \$val;
        } else {
            \$slf->__$_(1,\$val);
        }
    }
    if ( wantarray ) {
        return \@{\$slf->__$_()};
    } else {
        return \${\$slf->__$_()}[0];
    }
}
EOT
        }
    }

    my $warn = $^W;
    $^W = 0; # Eliminates useless "warnings" during make test.
    eval "{package WWW::Search::Scraper::Response$SubClass; $accessors } 1";
    $^W = $warn;
    die $@ if $@;
    
    return $self;
}

sub plug_elem {
    my ($self, $name, $value) = @_;
    return unless defined $name;
    $self->_elem($name, $value);
    $self->$name(\$value);
}
sub plug_url {
    my ($self, $url) = @_;
    $self->add_url($url);
    $self->url(\$url);
}


# Return a table of names and origins for all data result columns.
sub GetFieldNames {
    $_[0]->_fieldNames();
}

# Return a table of names and titles for all data result columns.
sub GetFieldTitles {
    my ($self) = @_;
    my $answer = {'url' => 'URL'};
    for ( keys %$self ) {
        $answer->{$_} = $_ unless $_ =~ /^_/  or $_ =~ /^WWW::Search/;
    }
    return $answer;
}


sub GetFieldValues {
    my $self = shift;
    my $answer = {
#                'relevance'  => $self->relevance()
               'url'        => scalar $self->url()
           };
    for ( keys %$self ) {
        $answer->{$_} = $self->{$_} unless $_ =~ /^_/ or $_ eq 'url';
    }
    return $answer;
}

# This gets the target document via HTTP GET, if needed.
sub response {
    my ($self) = @_;

    my $request = HTTP::Request->new(GET => ${$self->url()});
    $self->{'_response'} = $self->_searchObject()->{'user_agent'}->request($request);
    return $self->{'_response'};
}


sub content {
    my ($self) = @_;

    my $response = $self->response();
    return $response->content() if $response->is_success;
    return undef;
}

# Pairs in the $anchors hash are combined into <A> anchor tags.
sub toHTML {
    my ($self, $anchors) = @_;
    
    my $result = "<TABLE BORDER='4'  WIDTH='480'>"; #<DT>from:</DT><DD>".$self->{'searchObject'}->getName()."</DD>\n";
    my %results = %{$self->GetFieldValues()};
    my %resultTitles = %{$self->GetFieldTitles()};
    
    my $url = $results{'url'};
    $url = $$url if ref($url);
    $result .= "<TR><TD COLSPAN='3'>$resultTitles{'title'}: <A HREF='#' onclick='window.open(\"$url\",\"$resultTitles{'title'}\")'>$results{'title'}</A></TD></TR>\n";
    
    $result .= "<TR><TD COLSPAN='3'>$resultTitles{'company'}: <A HREF='$results{'companyProfileURL'}'>$results{'company'}</A></TD></TR>\n"
        if ($results{'companyProfileURL'});

    for my $title ( keys %resultTitles ) {
        next if $title eq 'companyProfileURL' or $title eq 'company';
        next if $title eq 'url' or $title eq 'title';
        next unless $results{$title};
        my $rslt = $results{$title};
        $rslt = [$rslt] unless ref $rslt;
         $result .= "<TR><TD COLSPAN='1'>$resultTitles{$title}</TD><TD COLSPAN='2'>";
        my $comma = '';
        for ( @$rslt ) {
           if ( $resultTitles{$title} =~ m{url}i ) {
              $result .= "$comma<a href=\"$_\">$_</a>";
           } else {
              $result .= "$comma$_";
           }
           $comma = "<BR>"
        }
        $result .= "</TD></TR>\n";
    }
    return $result.'</TABLE>';
}


sub SkipDetailPage {
    my $self = shift;
    return $self->_skipDetailPage() if $_[0] < 1 or $_[0] > 3;
    $self->_skipDetailPage(@_);
}

# Fetch and scrape the detail page if necessary.
sub ScrapeDetailPage {
    my $self = shift;

    return if defined($self->_skipDetailPage()) && $self->_skipDetailPage() == 1;
    
    my $detail = $self->_gotDetailPage();
    return if $detail;

    my $scraper = $self->_ScraperEngine();
    my $url = $self->url();
    $url = $$url if ref $url;
    eval {
        # Why does http_request() cause Scraper::Brainpower to fail "Object Not Found" on next_url?        
        # this code from WWW::Search::http_request().
        use HTTP::Request;
        my $request = new HTTP::Request('GET', $url);
        
        if ($scraper->is_http_proxy_auth_data)
        {
            $request->proxy_authorization_basic($scraper->http_proxy_user,
                                                $scraper->http_proxy_pwd);
        }
        $scraper->{'_cookie_jar'}->add_cookie_header($request) if ref($scraper->{'_cookie_jar'});
        
        my $ua = $scraper->{'user_agent'};
        $detail = $ua->request($request)->content();
    };
    return if $@;
        
    $self->_gotDetailPage($detail);
    my $debug = '';
    $scraper->scrape($detail, $debug, $scraper->scraperDetail(), $self);
}
1;

