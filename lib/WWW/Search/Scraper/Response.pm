package WWW::Search::Scraper::Response;


=head1 NAME

WWW::Search::Scraper::Response - result class of generic scrapes.


=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 OPTIONS

None at this time (2001.04.25)

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
$VERSION = sprintf("%d.%02d", q$Revision: 1.8 $ =~ /(\d+)\.(\d+)/);
require WWW::SearchResult;
my %AlreadyDeclared;


sub fieldCapture {
    my ($scaffold) = @_;
    my @fields;
    my $next_scaffold;
SCAFFOLD: for my $scaffold ( @$scaffold ) {
        $next_scaffold = undef;
        
        my $tag = $$scaffold[0];
        if ( $tag =~ m/HIT|HIT\*|HTML/ )
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
        } elsif ('BODY' eq $tag) { # 'BODY', 'x', 'y' , [[.]]
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
            push @fields, @ary;
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

        my @subFields = join '\'=>\'$\',\'', keys %subFields;
        my $subFieldsStruct = join '\'=>\'$\',\'', join '\'=>\'$\',\'', keys %subFields;
        
        die "No fields were found in the scraperFrames for WWW::Search::Scraper$SubClass\n" unless keys %subFields;

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
,'$subFieldsStruct'=>'\$'
                }
           );
}

package WWW::Search::Scraper::Response$SubClass;
use WWW::Search::Scraper::Response;
use base qw( WWW::Search::Scraper::Response$SubClass\::_struct_ WWW::Search::Scraper::Response );

        
1;
EOT
        die $@ if $@;
        $AlreadyDeclared{$SubClass} = [(keys %subFields)+11, \%subFields];
    }
    
    eval "\$self = new WWW::Search::Scraper::Response$SubClass;";
    die $@ if $@;
    
    $self->_fieldCount(${AlreadyDeclared{$SubClass}}[0]);
    $self->_fieldNames(${AlreadyDeclared{$SubClass}}[1]);

    # Build lazy-accessors for fields available from the Details page.
    my $fieldNames = $self->_fieldNames();
    my $detailAccessors = "\n";
    for ( keys %$fieldNames ) {
        if ( $fieldNames->{$_} > 1 ) {
            $detailAccessors .= "sub $_ { my \$slf = shift; \$slf->ScrapeDetailPage() if defined \$_[0]; \$slf->SUPER::$_(\@_) }\n";
        }
    }
    my $warn = $^W;
    $^W = 0; # Eliminates useless "warnings" during make test.
    eval "{package WWW::Search::Scraper::Response$SubClass; $detailAccessors } 1";
    $^W = $warn;
    die $@ if $@;
    

    return $self;
}


sub plug_elem {
    my ($self, $name, $value) = @_;
    return unless $name;
    $self->_elem($name, $value);
    $self->$name(\$value);
}
sub plug_url {
    my ($self, $url) = @_;
    $self->add_url($url);
    $self->url(\$url);
}


# Return a table of names and titles for all data result columns.
sub resultTitles {
    my ($self) = @_;
    my $answer = {'url' => 'URL'};
    for ( keys %$self ) {
        $answer->{$_} = $_ unless $_ =~ /^_/ or $_ eq 'searchObject' or $_ =~ /^WWW::Search/;
    }
    return $answer;
}


sub results {
    my $self = shift;
    my $answer = {
#                'relevance'  => $self->relevance()
               'url'        => $self->url()
           };
    for ( keys %$self ) {
        $answer->{$_} = $self->{$_} unless $_ =~ /^_/ or $_ eq 'searchObject' or $_ eq 'url';
    }
    return $answer;
}

sub relevance { return $_[0]->_elem('result_relevance'); }
#  sub url () {} - identical to WWW::SearchResult.

# This gets the target document via HTTP GET, if needed.
sub response {
    my ($self) = @_;

    my $request = HTTP::Request->new(GET => $self->url());
    $self->{'_response'} = $self->{'searchObject'}->{'user_agent'}->request($request);
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
    my %results = %{$self->results()};
    my %resultTitles = %{$self->resultTitles()};
    
    $result .= "<TR><TD COLSPAN='3'>$resultTitles{'title'}: <A HREF='$results{'url'}'>$results{'title'}</A></TD></TR>\n";
    
    $result .= "<TR><TD COLSPAN='3'>$resultTitles{'company'}: <A HREF='$results{'companyProfileURL'}'>$results{'company'}</A></TD></TR>\n"
        if ($results{'companyProfileURL'});

    for ( keys %resultTitles ) {
        next if $_ eq 'companyProfileURL' or $_ eq 'company';
        next if $_ eq 'url' or $_ eq 'title';
        next unless $results{$_};
        $result .= "<TR><TD COLSPAN='1'>$resultTitles{$_}</TD><TD COLSPAN='2'>$results{$_}</TD></TR>\n";
    }
#    $result .= "<DT>from:</DT><DD>".$self->{'searchObject'}->getName()."</DD>\n";
    return $result.'</TABLE>';
}


# Fetch and scrape the detail page if necessary.
sub ScrapeDetailPage {
    my $self = shift;

    return if $self->_skipDetailPage();
    
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

