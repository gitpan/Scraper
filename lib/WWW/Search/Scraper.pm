
####################################################################################
#########################################dsf###########################################
####################################################################################
####################################################################################
package WWW::Search::Scraper;

use strict;
require Exporter;
use vars qw($VERSION $MAINTAINER @ISA @EXPORT @EXPORT_OK);
@EXPORT = qw(testParameters);

$VERSION = '2.18';

my $CVS_VERSION = sprintf("%d.%02d", q$Revision: 1.60 $ =~ /(\d+)\.(\d+)/);
$MAINTAINER = 'Glenn Wood http://search.cpan.org/search?mode=author&query=GLENNWOOD';

use Carp ();
use WWW::Search( 2.28, qw(strip_tags) );
use WWW::Search::Scraper::Request;
use WWW::Search::Scraper::Response;
use WWW::Search::Scraper::TidyXML;

@EXPORT_OK = qw(escape_query unescape_query generic_option 
                strip_tags trimTags trimLFs trimLFLFs
                @ENGINES_WORKING addURL trimXPathAttr trimXPathHref
                findNextForm findNextFormInXML removeScriptsInHTML cleanupHeadBody);


# Here we begin our gradual migration from "can-o-worms" to Class::Struct structured Scraper.
{ package WWW::Search::Scraper::_struct_;
use Class::Struct;
    struct ( 'WWW::Search::Scraper::_struct_' =>
              {
                  'response'         => '$'
                 ,'searchEngineHome' => '$'
                 ,'searchEngineLogo' => '$'
                 ,'errorMessage'     => '$'
                 ,'_forInterator'    => '$'
              }
           );
}
use base qw( WWW::Search::Scraper::_struct_ WWW::Search Exporter );


sub new {
    my ($class, $subclass, $searchName) = @_;
    
    my $self;
    if ( $subclass =~ m-^\.\.[\/](.*)$- ) {  # Allow the form "../name" to indicate
        $self = new WWW::Search($1);          # a WWW::Search backend. Also see "Some 
        bless $self, 'WWW::Search::Scraper'; # searchers are not scrapers", below.
    } else {
        if ( $subclass =~ s/^(.*)\((.*)\)$/$1/ ) {
            my $subclassVersion = $2;
            eval "use WWW::Search::Scraper::$subclass($subclassVersion)";
            if ( $@ ) {
                print "Can't use engine $subclass($subclassVersion): $@\n";
                return undef;
            }
        }
        $self = new WWW::Search("Scraper::$subclass");
#        bless $self, "Scraper::$subclass";
    }

    $self->{'agent_name'} = "Mozilla/WWW::Search::Scraper/$VERSION";
    $self->{'agent_e_mail'} = 'glenwood@alumni.caltech.edu;MartinThurn@iname.com';

    $self->{'scraperQF'} = 0; # Explicitly declare 'scraperQF' as the deprecated mode.
    $searchName = $subclass unless $searchName;
    $self->{'scraperName'} = $searchName;

    # Finally, call the sub-scraper's init() method.
    $self->init();

    return $self;
}

# The sub-scraper should override this.
sub init {
}


# To help avoid embarrassment when Glenn releases test, debug or tracing code to CPAN, Glenn uses this.
sub isGlennWood { return $ENV{'VSROOT'} and ($ENV{'USERNAME'} eq 'Glenn') and ($ENV{'USERDOMAIN'} eq 'ORCHID'); }

# Return empty testFrame for sub-scrapers that choose not to provide one.
sub testParameters {
    my ($self) = @_;

    if ( ref $self ) {
        $self->{'isTesting'} = 1;
    }
    
    my $isNotTestable = WWW::Search::Scraper::isGlennWood()?0:'No testParameters provided.';
    return { 
             'isNotTestable' => $isNotTestable
            ,'testNativeQuery' => 'search scraper'
            ,'expectedOnePage' => 9
            ,'expectedMultiPage' => 11
            ,'expectedBogusPage' => 0
           };
}

sub generic_option 
{
    my ($option) = @_;
    return 1 if $option =~ /^scrape/;
    return WWW::Search::generic_option($option);
}

# A generalize get/set method for object attributes.
sub _attr {
    my ($self, $attr, $value) = @_;
    my $rtn = $self->{$attr};
    $self->{$attr} = $value if defined $value;
# neat idea, but we've got to rewrite a lot of method invocations to make this ok. gdw.2001.07.04
#    if ( wantarray ) {
#        return $rtn if 'ARRAY' eq ref $rtn;
#        return [$rtn];
#    }
    return $rtn;
}
# ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## 
### # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## 
## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## #
sub query          { $_[0]->_attr('_query', $_[1]) }
sub queryDefaults  { $_[0]->_attr('_queryDefaults', $_[1]) }
sub queryOptions   { $_[0]->_attr('_queryOptions', $_[1]) }
sub fieldTranslations  { $_[0]->_attr('_fieldTranslations', $_[1]) }

# backward compatible
sub scraperFrame {
    $_[0]->{'_options'}{'scrapeFrame'} = $_[1] if $_[1];
    return $_[0]->{'_options'}{'scrapeFrame'}
}
sub scraperDetail{ undef }

# Some tracing options -
#   U - lists URLs as they are generated/accessed.
#   T - lists progress of each TidyXML tree-walking operation.
#   d - excruciating details about parsing the results and details pages.
sub ScraperTrace {
    return $_[0]->{'_traceFlags'} unless $_[1]; # default traceFlags if no match string sent.
    return ( $_[0]->{'_traceFlags'} =~ m-$_[1]- );
}
sub setScraperTrace {
    $_[0]->{'_traceFlags'} = $_[1];
}

# ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## 
### # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## 
## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## #
sub request {
    my ($self, $rqst) = @_;
    
    my $nonBlankWWWSearchNativeQuery = 'nonBlankWWWSearchNativeQuery';
    if ( $rqst ) {
        # Make sure the request object is ready for us.
        $rqst->prepare($self);
        
        # Move the debug option from the request to the Scraper module.
        $self->{'_debug'} = $rqst->_Scraper_debug();

        $self->{'_scraperRequest'} = $rqst;
        
        $nonBlankWWWSearchNativeQuery = $rqst->_native_query() || $nonBlankWWWSearchNativeQuery;
    }
    
    # WWW::Search(2.26) required native_query to be non-blank, even before it hands it off to Scraper!
    $self->{'native_query'} = $nonBlankWWWSearchNativeQuery unless $self->{'native_query'};

    return $self->{'_scraperRequest'};
}



sub native_setup_search
{
    my $self = shift;
    my ($native_query, $native_options) = @_;
    $native_query = WWW::Search::unescape_query($native_query); # Thanks, but no thanks, Search.pm!

    $self->{'_first_url'} = undef;
    $self->{'_first_url_method'} = undef;

    # Provides some backward compatibility, perhaps . . .
    $self->{'_options'}{'scraperQuery'} = $self->scraperQuery();
    my $scraperQuery = $self->scraperQuery();

    # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## 
    #
    # This pecular set of code translates old interface mode into 'canonical request' mode,
    #  (unless canonical request 'scraperRequest' is active already).
    #
    # NOTE THAT IF THE CANONICAL REQUEST HAS BEEN SET, ALL native_setup_search() PARAMETERS ARE IGNORED!
    #
    # otherwise, they get picked up here.

    # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## 
    # Get the scraperQuery declaration of the Scraper module, or fake one (as in when using a WWW::Search module).
    unless ( $scraperQuery ) {
        $scraperQuery = 
            { 
                  'type' => 'SEARCH'    # This is a WWW::Search module - notify native_setup_search_NULL() of that.
                  # This is the basic URL on which to build the query.
                 ,'url' => 'http://'
                  # names the native input field to recieve the query string.
                 ,'nativeQuery' => 'query'
                  # specify defaults, by native field names
                 ,'nativeDefaults' => { }
                 ,'fieldTranslations' => undef # This gives us a null %inputsHash, so WWW::Search::Scraper will ignore that functionality (hopefully)
                 , 'cookies' => 0 # The WWW::Search module must maintain its own cookies.
            };
        $self->scraperQuery() = $scraperQuery;
    }
    # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## 
    
    $self->request( new WWW::Search::Scraper::Request() ) unless ( $self->request());

    # Gimmick to get native_query (ala WWW::Search) to work.
    $native_query = $self->request()->_native_query() unless $native_query;
    $self->request()->_native_query($native_query);

    # These traceFlags will ultimately come from many places . . .
    #$self->setScraperTrace($self->{'_debug'}) unless $self->{'_traceFlags'};

    for ( $self->scraperQuery()->{'type'} ) {
        m/SHERLOCK/ && do { return $self->native_setup_search_SHERLOCK(); };
        m/FORM/     && do { return $self->native_setup_search_FORM(); };
        m/QUERY/    && do { return $self->native_setup_search_QUERY(); };
        m/POST/     && do { $self->{'_http_method'} = 'POST';
                            return $self->native_setup_search_QUERY(); };
        m/SEARCH/   && do { return $self->native_setup_search_NULL(@_); };
        die "Invalid mode in WWW::Search::Scraper - '$_'\n";
    }
}



sub native_setup_search_SHERLOCK
{
    die "Unimplemented mode in WWW::Search::Scraper - 'SHERLOCK'\n";
}


sub native_setup_search_FORM
{
    my $self = shift;
    
    $self->user_agent('user');
    $self->{_next_to_retrieve} = 0;
    
    # $scraperForm = [ 'url', 'formIndex' (or formName, NYI), 'submitButtonName' or undef ]
    my $url = $self->scraperQuery(@_)->{'url'};
    if ( ref $url ) {
        $self->{'_base_url'} = &$url($self, $self->scraperRequest()->_native_query(), $self->{'native_options'});
    } else {
        $self->{'_base_url'} = $url;
    }
    unless ( $self->{'_base_url'} ) {
        print STDERR "No base url was specified by ".ref($self).".pm, so no search is possible.\n";
        undef $self->{'_next_url'};
        return undef;
    }
    $self->{'_http_method'} = 'GET' unless $self->{'_http_method'};    

    print STDERR 'FORM URL: '.$self->{'_base_url'} . "\n" if ($self->ScraperTrace('U'));
    my $response = $self->http_request($self->{'_http_method'}, $self->{'_base_url'});
    unless ( $response->is_success ) {
        print STDERR "Request for FORM failed in Scraper.pm: ".$response->message() if $self->ScraperTrace();
        return undef ;
    }
    
    my @forms = HTML::Form->parse($response->content(), $response->base());
    my $form = $forms[$self->scraperQuery()->{'formNameOrNumber'}];

    # Finally figure out the url.
    return undef unless $form;

    $self->{'_http_method'} = $self->{'search_method'} = uc $form->method() || 'POST';
    
    # Process the inputs.
    # Fill in the defaults, first
    my %optsHash = %{$self->queryDefaults()};
    # Override those with what came with the request.
    my $options_ref = $self->{'native_options'};
    foreach (sort keys %$options_ref) {
        $optsHash{$_} = $$options_ref{$_};
    };
    $optsHash{$self->scraperQuery()->{'nativeQuery'}} = $self->request()->_native_query() if $self->scraperQuery()->{'nativeQuery'};

    for my $key (sort keys %optsHash) {
        my $opts = $optsHash{$key};
#        if ( 'ARRAY' eq ref $opts ) {
#            for ( @$opts) {
#                $options .= "$key=".WWW::Search::escape_query($_)."&";
#            }
#        } else {
            my $field = $form->find_input($key);
            next unless $field;
            my $fldtyp = $field->type();
            if ( $fldtyp eq 'option' ) {
            my $n = 1;
            SUBFIELD: while ( my $field = $form->find_input($key, undef, $n++) ) {
                    for ( @{$field->{'menu'}} ) {
                        if ( $_ eq $opts ) {
                            $field->value($opts);
                            last SUBFIELD;
                        }
                    }
                }
#'password'', ``hidden'', ``textarea'', ``image'', ``submit'', ``radio'',
#``checkbox'', ``option''...my $x = $field->form_name_value();
            }
            else {
                $field->value($opts);
            }
        }
#bless( {
#      'seen' => [
#        1,
#        0
#      ],
#      'menu' => [
#        undef,
#        '2'
#      ],
#      'multiple' => 'multiple',
#      'current' => 0,
#      'size' => '4',
#      'type' => 'option',
#      'name' => 'countyIDs'
#    }, 'HTML::Form::ListInput' )
    
    my $submit_button = $form->find_input($self->scraperQuery()->{'submitButton'}, 'submit');
    $submit_button = $form->find_input($self->scraperQuery()->{'submitButton'}, 'image') unless $submit_button;
    die "Can't find 'submit' button named '".$self->scraperQuery()->{'submitButton'}."' in '$url'" unless $submit_button;
    my $req = $submit_button->click($form); #
#    $self->{_options}{'scraperRequest'} = $req;

    $self->{_base_url} = $self->{_next_url} = $req->uri();
    $self->{_base_url} .= '?'.$req->content() if $req->content();
    print STDERR "FORM SUBMIT: ".$self->{_base_url} . "\n" if $self->ScraperTrace('U');
}


sub native_setup_search_QUERY
{
    my $self = shift;
    
    $self->user_agent('user');
    $self->{_next_to_retrieve} = 0;
    
    my $url = $self->scraperQuery(@_)->{'url'};
    
    if ( ref $url ) {
        $self->{'_base_url'} = &$url($self, $self->scraperRequest()->_native_query(), $self->{'native_options'});
    } else {
        $self->{'_base_url'} = $url;
    }
    unless ( $self->{'_base_url'} ) {
        print STDERR "No base url was specified by ".ref($self).".pm, so no search is possible.\n";
        undef $self->{'_next_url'};
        return undef;
    }
    $self->{'_http_method'} = 'GET' unless $self->{'_http_method'};
#    $rqst->{'_base_url'} = $self->{'_base_url'};

    $self->{'_next_url'} = $self->generateQuery();

    print STDERR $self->{_next_url} . "\n" if $self->ScraperTrace('U');
}


# This one handles the deprecated Scraper::native_setup_search()
sub native_setup_search_NULL
{
    my $self = shift;
    
    die "native_setup_search_NULL() is no longer supported!";
    # This is a cheap way to get back to the non-canonical form.
    # We'll clean up the rest of this code later, so it won't look
    # like such a waste of time to prepare(canonical) just to come
    # back to the legacy form here. gdw.2001.06.30
    my ($native_query, $native_options_ref) = ($self->scraperRequest()->_native_query(), $self->{'native_options'});
    
    my $subJob = 'Perl';
    $self->user_agent('user');
    $self->{_next_to_retrieve} = 0;
    if (!defined($self->{_options})) {
	$self->{_options} = {
#	    'search_url' => 'http://www.defaultdomain.com/plus-cgi-bin/and-cgi-program-name'  SHOULD BE PASSED IN AS AN OPTION.
        };
    };
    $self->{'_http_method'} = 'GET';        # SHOULD BE PASSED IN AS AN OPTION; this is the default.
 
    my($options_ref) = $self->{_options};
    if (defined($native_options_ref)) {
	# Copy in new options.
	foreach (keys %$native_options_ref) {
	    $options_ref->{$_} = $native_options_ref->{$_};
	};
    };
    # Process the options.
    # (Now in sorted order for consistency regarless of hash ordering.)
    my($options) = '';
    foreach (sort keys %$options_ref) {
	# printf STDERR "option: $_ is " . $options_ref->{$_} . "\n";
	next if (generic_option($_));
	$options .= $_ . '=' . $options_ref->{$_} . '&';
    };
    $self->{_debug} |= $options_ref->{'search_debug'};
    $self->{_debug} = 2 if ($options_ref->{'search_parse_debug'});
    $self->{_debug} = 0 if (!defined($self->{_debug}));
    
    # Finally figure out the url.
    $self->{_base_url} = 
	$self->{_next_url} =
            	$self->{_options}{'search_url'} .
        	    "?" . $options .
            	"KEYWORDS=" . $native_query;

    print STDERR $self->{_next_url} . "\n" if $self->ScraperTrace('U');
}


### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 
# The options have been prepared into the Scraper module object.
# generateQuery() creates the HTTP query based on those options.
sub generateQuery {
    my ($self) = @_;

    # Process the inputs.
    # (Now in sorted order for consistency regardless of hash ordering.)
    my $options = ''; # Was scraperQuery, now fieldTranslations 
    
    # The following line allows us to use native_query(), ala pre-v2.00 modules, with this Scraper.pm
#    $options = $self->queryFieldName().'='.$rqst->_native_query().'&' if $rqst->_native_query() and $self->queryFieldName();

    # Fill in the defaults, first
    my %optsHash = %{$self->queryDefaults()};
    # Override those with what came with the request.
    my $options_ref = $self->{'native_options'};
    foreach (sort keys %$options_ref) {
        $optsHash{$_} = $$options_ref{$_};
    };

    for my $key (sort keys %optsHash) {
        my $opts = $optsHash{$key};
        if ( 'ARRAY' eq ref $opts ) {
            for ( @$opts) {
                $options .= "$key=".WWW::Search::escape_query($_)."&";
            }
        } else {
            $options .= "$key=".WWW::Search::escape_query($opts)."&";
        }
    };
    chop $options;
    return $self->{'_base_url'}.$options;
}



### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 
sub native_retrieve_some
{
    my ($self) = @_;
    my $debug = $self->{_debug};

    $self->{'total_hits_count'} = 0; # for HIT(i)

    # fast exit if already done
AGAIN:    
    unless ( defined($self->{_next_url}) ) {
        print STDERR "END_OF_SEARCH: _next_url is empty.\n" if $self->ScraperTrace('U');
        return undef;
    };
    
    # get some
     if ( $debug ) {
         my $obj = ref $self;
         print STDERR "$obj::native_retrieve_some: fetching " . $self->{_next_url} . "\n"  if ($self->ScraperTrace('U'));
     }
    my $method = $self->{'_http_method'};
    $method = 'POST' unless $method;

    print STDERR "Fetching NEXT_URL via $method: '".$self->{_next_url}."'\n" if $self->ScraperTrace('U');
    
    $self->{'_last_url'} = $self->{_next_url};
    unless ( $self->{'_first_url'} ) {
        $self->{'_first_url'} = $self->{_next_url};
        $self->{'_first_url_method'} = $method;
    }
    my $response = $self->http_request($method, $self->{_next_url});

    while ( $response->code() eq '302' ) {
        my $redirect = $response->header('location');
        if ( $redirect =~ m-^/- ) {
            my $url = $self->{_next_url};
            $url =~ m-^(\w+://[^/]*)/-;
            $url = $1;
            $self->{_next_url} = $url.$redirect;
        } elsif ( ! ($redirect =~ m-^(\w+://[^/]*)-) ) {
            my $url = $self->{_next_url};
            $url =~ m-^(.*/)-;
            $url = $1;
            $self->{_next_url} = $url.$redirect;
        } else {
            $self->{_next_url} = $redirect;
        }
        print STDERR "Redirected to: '".$self->{_next_url}."'\n" if $self->ScraperTrace('U');
        $method = $self->scraperQuery()->{'redirectMethod'} || $method;
        $response = $self->http_request($method, $self->{_next_url});
    }

    $self->{'_last_url'} = $self->{'_next_url'}; $self->{'_next_url'} = undef;
    $self->response($response);
    
    unless ( $response->is_success ) {
        $self->errorMessage("Request failed in Scraper.pm: ".$response->message());
        print STDERR $self->errorMessage()."\n" if $self->ScraperTrace();
        return undef;
    }

    my $hits_found = $self->scrape($response->content(), $self->{_debug});

    # sleep so as to not overload the engine
    $self->user_agent_delay if ( defined($self->{_next_url}) );
    
    return $hits_found;
}



### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 
# Given a candidate hit, do post-selection.
# Return 1 to keep this hit, 0 to cast it away.
sub postSelect {
    my ($self, $rqst, $rslt) = @_;
    # By default, the Request object will do the postSelect for the Scraper module.
    # If the Scraper module wants to override that, then it overrides this Scraper::postSelect().
    
    my $fields = $rqst->FieldTitles;
    
    my $fieldTranslationsTable = $self->fieldTranslations();
    my $fieldTranslations = $fieldTranslationsTable->{'*'}; # We'll do this until context sensitive work is done - gdw.2001.08.18
    my $fieldTranslation;

    for ( keys %$fields ) {
        $fieldTranslation = $$fieldTranslations{$_};
        next if defined $fieldTranslation and $fieldTranslation eq '';
        # 'fieldTranslation' may be a string naming the option, or 
        # a subroutine tranforming the field into a (nam,val) pair,
        # or a FieldTranslation object - that's the only one that'll have a postSelect() method!
        if ( 'CODE' eq ref $fieldTranslation ) {
        }
        elsif ( ref $fieldTranslation ) # We assume any other ref is an object of some sort.
        { 
            return 0 unless $fieldTranslation->postSelect($self, $rqst, $rslt);
        }
    }
    return $rqst->postSelect($self, $rslt);
}


{ package WWW::Search;
sub getName {
   return $_[0]->{'scraperName'};
}

}



{
    package LWP::RobotUA;

# Dice always redirects the first query page via 302 status code.
# BAJobs frequently (but not always) redirects via 302 status code.
# We need to tell LWP::RobotUA that it's ok to redirect on Dice and BAJobs.
sub redirect_ok
{
    # draft-ietf-http-v10-spec-02.ps from www.ics.uci.edu, specify:
    #
    # If the 30[12] status code is received in response to a request using
    # the POST method, the user agent must not automatically redirect the
    # request unless it can be confirmed by the user, since this might change
    # the conditions under which the request was issued.
    
    my($self, $request) = @_;
    return 1 if $request->uri() =~ m-seeker\.dice\.com/jobsearch/jobsearch_r\.epl-i;
    return 1 if $request->uri() =~ m-seeker\.dice\.com/jobsearch/resultSummary\.epl-i;
#    return 1 if $request->uri() =~ m-jobsearch\.dice\.com/jobsearch/jobsearch\.cgi-i;
    return 1 if $request->uri() =~ m-www\.bajobs\.com/jobseeker/searchresults\.jsp-i;
    return 1 if $request->uri() =~ m-\.techies\.com/Common-i;
    return 0 if $request->method eq "POST";
    1;
}
}


##################### < E X C E P T I O N S > ######################
# some kind of problem with URI in LWP since LWP(5.60)
eval <<EOT
    use URI::http;
    { package URI::http;
    sub abs {
        my \$self = shift;
        return \$self->SUPER::abs(\@_) if \$_[0];
        return \$self->canonical(\@_);
    }
    use URI::https;
    { package URI::https;
    sub abs {
        my \$self = shift;
        return \$self->SUPER::abs(\@_) if \$_[0];
        return \$self->canonical(\@_);
    }
EOT
if ( ($LWP::VERSION ge '5.60') and ($LWP::VERSION le '5.63') );
#################### < / E X C E P T I O N S > #####################


##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### 
 ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### 
  ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### 
   ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### 
    ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### 
     ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### 
     ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### 
    ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### 
   ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### 
  ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### 
 ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### 
##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### 

sub scrape { my ($self, $content, $debug, $scraperFrame, $hit) = @_;
    $scraperFrame = $self->scraperFrame() unless $scraperFrame;
   for (${$scraperFrame}[0]) {
       return $self->scraperHTML($scraperFrame, \$content, $hit, $debug) if m/HTML/;
       return $self->scraperTidyXML($scraperFrame, \$content, $hit, $debug) if m/TidyXML/;
   }
   die "Scraper format '${$self->scraperFrame()}[0]' is not implemented in version $VERSION of Scraper.pm for ".ref($self)."\n";
}

# private
sub scraperHTML { my ($self, $scaffold_array, $content, $hit, $debug) = @_;
    my $TidyXML = new WWW::Search::Scraper::TidyXML();
    $TidyXML->m_asString($content);
    return $self->scraper($$scaffold_array[1], $TidyXML, $hit, $debug);
}

# private
sub scraperTidyXML { my ($self, $scaffold_array, $content, $hit, $debug) = @_;
    # Execute any preprocessors this TidyXML may declare.
    my $i = 1;
    while ( 'ARRAY' ne ref $$scaffold_array[$i] ) {
        my $datParser = $$scaffold_array[$i];
        $i += 1;
        $content = &$datParser($self, $hit, $content);
    }
    my $TidyXML = new WWW::Search::Scraper::TidyXML($content);
    return $self->scraper($$scaffold_array[$i], $TidyXML, $hit, $debug);
}


# private
sub scraperRecurse { my ($self, $sub_string, $next_scaffold, $TidyXML, $hit, $debug) = @_;

    my $myTidyXML = $TidyXML;
    my ($saveContext, $saveFoundContext, $saveString);
    if ( $myTidyXML ) {
        $saveContext = $TidyXML->m_context();
        $saveFoundContext = $TidyXML->m_found_context();
        $myTidyXML->m_context($TidyXML->m_found_context);
        $saveString = $myTidyXML->m_asString();
        if ( $$sub_string ) {
            $myTidyXML->m_asString($sub_string);
        }
    } else {
        $myTidyXML = new WWW::Search::Scraper::TidyXML;
        $myTidyXML->m_asString($sub_string);
    }
    
    my $total_hits_found = $self->scraper($next_scaffold, $myTidyXML, $hit, $debug);

    $myTidyXML->m_context($saveContext);
    $myTidyXML->m_found_context($saveFoundContext);
    $myTidyXML->m_asString($saveString);

    return $total_hits_found;
}
   
# private
sub scraper { my ($self, $scaffold_array, $TidyXML, $hit, $debug) = @_;

	# Here are some variables that we use frequently done here.
    my $total_hits_found = 0; # counts hits, and is boolean for "any-hit-found".
    
    my $sub_string = undef;
    my $next_scaffold = undef;
    $TidyXML->m_TRACE($self->{'_traceFlags'}) if $TidyXML;

    my (@ary,@dts); # 'F' and 'REGEX' are co-functional, so we need these shared variables here.

SCAFFOLD: for my $scaffold ( @$scaffold_array ) {
        my $tag = $$scaffold[0];
        print "TAG: $tag\n" if $debug > 1;

        # 'HIT*' is special since it has pre- and post- processing (adding the hits to the hit-list).
        # All other tokens simply process data as it moves along, then they're done,
        #  so they will do a set up, then pass along to recurse on scraper() . . .
        if ( 'HIT' eq $tag ) {
            $self->{'total_hits_count'} = 1;
            my $resultType = $$scaffold[1];
            if ( 'ARRAY' eq ref $resultType ) {
                $next_scaffold = $resultType;
                $resultType = '';
            }
            $next_scaffold = $$scaffold[2];
            $next_scaffold = $$scaffold[1] unless defined $next_scaffold;
            #tidy $sub_content = $TidyXML->asString();
        }
        elsif ( 'HIT*' eq $tag )
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
            }
            $next_scaffold = $$scaffold[2];
            $next_scaffold = $$scaffold[1] unless defined $next_scaffold;
            my $hit;
            do 
            {
                $self->{'total_hits_count'} += 1;
                if ( $hit && $self->postSelect($self->request(), $hit) )
                {
                    push @{$self->{cache}}, $hit;
                    $total_hits_found += 1;
                }
                $hit = $self->newHit($resultType, $next_scaffold, $self->scraperDetail());
                $hit->_searchObject($self);
            
            } while ( $self->scraperRecurse($TidyXML->asString(), $next_scaffold, $TidyXML, $hit, $debug) );
            next SCAFFOLD;
        }
    
        elsif ( 'BODY' eq $tag )
        {  
            $sub_string = undef;
            if ( $$scaffold[1] and $$scaffold[2] ) {
                ${$TidyXML->asString()} =~ s-$$scaffold[1](.*?)$$scaffold[2]--si; # Strip off the adminstrative clutter at the beginning and end.
                $sub_string = $1;
            } elsif ( $$scaffold[1] ) {
                ${$TidyXML->asString()} =~ s-$$scaffold[1](.*)$-$1-si; # Strip off the adminstrative clutter at the beginning.
                $sub_string = $1;
            } elsif ( $$scaffold[2] ) {
                ${$TidyXML->asString()} =~ s-^(.*?)$$scaffold[2]-$1-si; # Strip off the adminstrative clutter at the end.
                $sub_string = $1;
            } else {
                next SCAFFOLD;
            }
            if ( 'ARRAY' ne ref $$scaffold[3]  ) # if next_scaffold is an array ref, then we'll recurse (below)
            {
                next SCAFFOLD unless $sub_string;

                my $binding = $$scaffold[3];
                my $datParser = $$scaffold[4];
                print STDERR  "raw dat: '$sub_string'\n" if ($self->ScraperTrace('d'));
                if (  $self->ScraperTrace('d') ) { # print ref $ aways does something screwy
                    print STDERR  "datParser: ";
                    print STDERR  ref $datParser;
                    print STDERR  "\n";
                };
                $datParser = \&WWW::Search::Scraper::trimTags unless $datParser;
                print STDERR  "binding: '$binding', " if ($self->ScraperTrace('d'));
                print STDERR  "parsed dat: '".&$datParser($self, $hit, $sub_string)."'\n" if ($self->ScraperTrace('d'));
                if ( $binding eq 'url' )
                {
                    my $url = new URI::URL(&$datParser($self, $hit, $sub_string), $self->{_base_url});
                    $url = $url->abs();
                    $hit->plug_url($url);
                } 
                elsif ( $binding) {
                    $hit->plug_elem($binding, &$datParser($self, $hit, $sub_string));
                }
                $total_hits_found = 1;
                next SCAFFOLD;
            } else {
                $next_scaffold = $$scaffold[3];
            }
        }
    	
        elsif ( 'CALLBACK' eq $tag ) {
            ($sub_string, $next_scaffold) = &{$$scaffold[1]}($self, $hit, $TidyXML->asString(), $scaffold, \$total_hits_found);
            next SCAFFOLD unless $next_scaffold;
        }
    	
        elsif ( 'DATA' eq $tag )
        {
            $sub_string = '';
            if ( $$scaffold[1] and $$scaffold[2] ) {
                ${$TidyXML->asString()} =~ s-$$scaffold[1](.*?)$$scaffold[2]--si;
                $sub_string = $1;
            } else {
                next SCAFFOLD;
            }
            my $binding = $$scaffold[3];
            $hit->plug_elem($binding, $sub_string);
            $total_hits_found = 1;
            next SCAFFOLD;
        }
    	
        elsif ( 'COUNT' eq $tag )
    	{
            $self->approximate_result_count(0);
    		if ( ${$TidyXML->asString()} =~ m/$$scaffold[1]/si )
    		{
    			print STDERR  "approximate_result_count: '$1'\n" if ($self->ScraperTrace('d'));
    			$self->approximate_result_count ($1);
                next SCAFFOLD;
    		}
            else {
                print STDERR "Can't find COUNT: '$$scaffold[1]'\n" if ($self->ScraperTrace('d'));
            }
    	}

        elsif ( 'NEXT' eq $tag )
        {
            # This accommodates a pre-1.41 method for specifying 'NEXT'
            $$scaffold[1] = $$scaffold[2] 
                if ( $$scaffold[1] eq 1 or $$scaffold[1] eq 2 );

            if ( ref $$scaffold[1] )
            {
                my $datParser = $$scaffold[1];
                my $url = ${$TidyXML->asString()};
                $url = WWW::Search::Scraper::unescape_query($url) if $TidyXML->m_isTidyd();
                $self->{'_next_url'} = &$datParser($self, $hit, $url);                
                print STDERR  "NEXT_URL: $self->{'_next_url'}\n" if ($self->ScraperTrace('U'));
                next SCAFFOLD;
            }
            else
            {
                # A simple regex will not work here, since the "next" string may often
                # appear even when there's no <A>...</A> surrounding it. The problem occurs
                # when there is a <A>...</A> preceding it, *and* following it. Simple regex's
                # will find the first anchor, even though it's not the HREF for the "next" string.
                my $next_url_button = $$scaffold[2]; # accomodates some earlier versions of Scraper.pm modules.
                $next_url_button = $$scaffold[1] unless $next_url_button;
                print STDERR  "next_url_button: $next_url_button\n" if ($self->ScraperTrace('N'));
                my $next_content = ${$TidyXML->asString()};
                
                while ( my ($sub_string, $url) = $self->getMarkedText('A', \$next_content) ) 
                {
                    last unless $sub_string;
                    if ( $sub_string =~ m-$next_url_button-si )
                    {
                        $url =~ s-A\s+HREF=--si;
                        if ( $url =~ m-^'([^']*)'\s*$- ) {
                            $url = $1;
                        }
                        elsif ( $url =~ m-^"([^"]*)"\s*$- ) {
                            $url = $1;
                        }
                        elsif ( $url =~ m-^([^ >]*)- ) {
                            $url = $1;
                        } else {
                            $url = '';
                        }
                        if ( $url ) {
                            my $datParser = $$scaffold[3];
                            $datParser = \&WWW::Search::Scraper::null unless $datParser;
                            $self->{'_base_url'} =~ m-^(.*)/.*$-;
                            my $baseURL = $1;
                            $url = new URI::URL(&$datParser($self, $hit, $url), $self->{'_base_url'});
                            $url = $url->abs();
                        }
                        $url = WWW::Search::Scraper::unescape_query($url);# if $TidyXML->m_isTidyd();
                        $self->{'_next_url'} = $url;
                        print STDERR  "NEXT_URL: $url\n" if ($self->ScraperTrace('U'));
                        next SCAFFOLD;
                    }
                }
            }
            next SCAFFOLD;
        }

        elsif ( 'HTML' eq $tag )
        {
            ${$TidyXML->asString()} =~ m-<HTML>(.*)</HTML>-si;
            $sub_string = $1;
            $next_scaffold = $$scaffold[1];
        }

    	elsif ( $tag =~ m/^(TABLE|TR|DL|FORM)$/ )
    	{
            my $tagLength = length $tag + 2;
            my $elmName = $$scaffold[1];
            $elmName = '#0' unless $elmName;
            if ( 'ARRAY' eq ref $$scaffold[1] )
            {
                $next_scaffold = $$scaffold[1];
            }
            elsif ( $elmName =~ /^#(\d*)$/ )
    		{
                for (1..$1)
    			{
                    $TidyXML->getMarkedText($tag); # and throw it away.
    			}
                $next_scaffold = $$scaffold[2];
            }
            else {
                print STDERR  "elmName: $elmName\n" if ($self->ScraperTrace('d'));
                $next_scaffold = $$scaffold[2];
                die "Element-name form of <$tag> is not implemented, yet.";
            }
            next SCAFFOLD unless $sub_string = $TidyXML->getMarkedText($tag);
        }
    	

    	elsif ( 'TAG' eq $tag )
        {
            next SCAFFOLD unless $sub_string = $TidyXML->getMarkedText($$scaffold[1]); # and throw it away.
            $next_scaffold = $$scaffold[2];
            if ( 'ARRAY' ne ref $next_scaffold  ) # if next_scaffold is an array ref, then we'll recurse (below)
            {
                my $binding = $next_scaffold;
                my $datParser = $$scaffold[3];
                print STDERR  "raw dat: '$sub_string'\n" if ($self->ScraperTrace('d'));
                if (  $self->ScraperTrace('d') ) { # print ref $ aways does something screwy
                  print STDERR  "datParser: ".ref($datParser)."\n";
                };
                $datParser = \&WWW::Search::Scraper::trimTags unless $datParser;
                print STDERR  "binding: '$binding', " if ($self->ScraperTrace('d'));
                print STDERR  "parsed dat: '".&$datParser($self, $hit, $sub_string)."'\n" if ($self->ScraperTrace('d'));
                if ( $binding eq 'url' )
                {
                   my $url = new URI::URL(&$datParser($self, $hit, $sub_string), $self->{_base_url});
                   $url = $url->abs();
                   $hit->plug_url($url);
                } 
                elsif ( $binding) {
                   $hit->plug_elem($binding, &$datParser($self, $hit, $sub_string));
                }
                $total_hits_found = 1;
                next SCAFFOLD;
            }
        }

#    	elsif ( 'F' eq $tag )
#        {
#            $tag = $$scaffold[1];
#            next SCAFFOLD unless $sub_string = $TidyXML->getMarkedText($tag); # and throw it away.
##    		next SCAFFOLD unless ( $$content =~ s-(<$tag\s*[^>]*>(.*?)</$tag\s*[^>]*>)--si );  $sub_content = $2;
#    		$next_scaffold = $$scaffold[2];
#            if ( 'ARRAY' ne ref $next_scaffold  ) # if next_scaffold is an array ref, then we'll recurse (below)
#            {
#               my $binding = $next_scaffold;
#               my $datParser = $$scaffold[3];
#               print STDERR  "raw dat: '$sub_string'\n" if ($self->ScraperTrace('d'));
#               if (  $self->ScraperTrace('d') ) { # print ref $ aways does something screwy
#                  print STDERR  "datParser: ";
#                  print STDERR  ref $datParser;
#                  print STDERR  "\n";
#               };
#               $datParser = \&WWW::Search::Scraper::trimTags unless $datParser;
#               print STDERR  "binding: '$binding', " if ($self->ScraperTrace('d'));
#               print STDERR  "parsed dat: '".&$datParser($self, $hit, $sub_string)."'\n" if ($self->ScraperTrace('d'));
#                if ( $binding eq 'url' )
#                {
#                    my $url = new URI::URL(&$datParser($self, $hit, $sub_string), $self->{_base_url});
#                    $url = $url->abs();
#                    $hit->plug_url($url);
#                } 
#                elsif ( $binding) {
#                    $hit->plug_elem($binding, &$datParser($self, $hit, $sub_string));
#                }
#                $total_hits_found = 1;
#                next SCAFFOLD;
#            }
#        }
    	
        elsif ( $tag =~ m/^(TD|DT|DD|DIV)$/ )
        {
            next SCAFFOLD unless $sub_string = $TidyXML->getMarkedText($tag); # and throw it away.
    		$next_scaffold = $$scaffold[1];
            if ( 'ARRAY' ne ref $next_scaffold  ) # if next_scaffold is an array ref, then we'll recurse (below)
            {
               my $binding = $next_scaffold;
               my $datParser = $$scaffold[2];
               print STDERR  "raw dat: '$sub_string'\n" if ($self->ScraperTrace('d'));
               if (  $self->ScraperTrace('d') ) { # print ref $ aways does something screwy
                  print STDERR  "datParser: ";
                  print STDERR  ref $datParser;
                  print STDERR  "\n";
               };
               $datParser = \&WWW::Search::Scraper::trimTags unless $datParser;
               print STDERR  "binding: '$binding', " if ($self->ScraperTrace('d'));
               print STDERR  "parsed dat: '".&$datParser($self, $hit, $sub_string)."'\n" if ($self->ScraperTrace('d'));
                if ( $binding eq 'url' )
                {
                    my $url = new URI::URL(&$datParser($self, $hit, $sub_string), $self->{_base_url});
                    $url = $url->abs();
                    $hit->plug_url($url);
                } 
                elsif ( $binding) {
                    $hit->plug_elem($binding, &$datParser($self, $hit, $sub_string));
                }
                $total_hits_found = 1;
                next SCAFFOLD;
            }
        }
        elsif ( 'A' eq $tag ) 
        {
            my $lbl = $$scaffold[1];
            my $anchor;
            next SCAFFOLD unless ($sub_string, $anchor) = $TidyXML->getMarkedText('A'); # and throw it away.
            if ( ( $anchor =~ s-A\s.*?HREF=(["'])([^"']+?)\1--si) or
                 ( $anchor =~ s-A\s.*?HREF(=)([^> ]+)--si) 
               )
            {
                print "<A> binding: $$scaffold[2]: '$sub_string', $$scaffold[1]: '$2'\n" if ($self->ScraperTrace('d'));
                my $datParser = $$scaffold[3];
                $datParser = \&WWW::Search::Scraper::trimTags unless $datParser;
                $hit->plug_elem($$scaffold[2], &$datParser($self, $hit, $sub_string));

               my ($url) = new URI::URL($2, $self->{_base_url});
               $url = $url->abs();
               if ( $lbl eq 'url' ) {
                   $url = WWW::Search::Scraper::unescape_query($url) if $TidyXML->m_isTidyd();
                   $hit->plug_url($url);
               }
               else {
                   $hit->plug_elem($lbl, $url);
               }
               $total_hits_found = 1;
            }
            next SCAFFOLD;
        }
        elsif ( 'AN' eq $tag ) 
        {
            my $lbl = $$scaffold[1];
            if ( ${$TidyXML->asString()} =~ s-<A[^>]+?HREF=([^>]+)>(.*?)</A>--si )
            {
                print "<A> binding: $$scaffold[2]: '$2', $$scaffold[1]: '$1'\n" if ($self->ScraperTrace('d'));
                
                my $datParser = $$scaffold[3];
                $datParser = \&WWW::Search::Scraper::trimTags unless $datParser;
                $hit->plug_elem($$scaffold[2], &$datParser($self, $hit, $2));

               my ($url) = new URI::URL($1, $self->{_base_url});
               $url = $url->abs();
               if ( $lbl eq 'url' ) {
                   $url = WWW::Search::Scraper::unescape_query($url) if $TidyXML->m_isTidyd();
                   $hit->plug_url($url);
               }
               else {
                   $hit->plug_elem($lbl, $url);
               }
               $total_hits_found = 1;
            }
            next SCAFFOLD;
        }
        elsif ( 'F' eq $tag ) 
        {
            @ary = @$scaffold;
            shift @ary;
            my $datParser = shift @ary;
            $datParser = \&WWW::Search::Scraper::trimTags unless $datParser;
            @dts = &$datParser($self, $hit, ${$TidyXML->asString()});
            goto REGEX_F;
        }
        elsif ( 'REGEX' eq $tag ) 
        {
            @ary = @$scaffold;
            shift @ary;
            my $regex = shift @ary;
            if ( ${$TidyXML->asString()} =~ s/$regex//si )
            {
                @dts = ($1,$2,$3,$4,$5,$6,$7,$8,$9);
            REGEX_F:    
                for ( @ary ) 
                {
                    if ( $_ eq '' ) {
                        shift @dts;
                    }
                    elsif ( $_ eq 'url' ) {
                        my $url = new URI::URL(shift @dts, $self->{_base_url});
                        $url = $url->abs();
                        $hit->plug_url($url);
                    } 
                    else {
                        $hit->plug_elem($_, $self->trimTags($hit, shift @dts));
                    }
                }
                $total_hits_found = 1;
            }
            next SCAFFOLD;
        } elsif ( $tag eq 'RESIDUE' )
        {
            $sub_string = ${$TidyXML->asString()};
            my $binding = $$scaffold[1];
            my $datParser = $$scaffold[2];
            $datParser = \&WWW::Search::Scraper::null unless $datParser;
            $hit->plug_elem($binding, &$datParser($self, $hit, $sub_string));
            next SCAFFOLD;

        } elsif ( $tag eq 'FOR' ) {
            my $iterator = $$scaffold[1];
            my $iterationString = $$scaffold[2];
            $next_scaffold = $$scaffold[3];
            my ($i,$j) = ($iterationString =~ m/^(\d+)\.\.(\d+)$/);
            for my $itr ($i..$j) {
                $self->_forInterator($itr);
                $total_hits_found += $self->scraperRecurse(\$sub_string, $next_scaffold, $TidyXML, $hit, $debug);
            }
        } elsif ( $tag eq 'XPath' )
        {
            my $xpath = $$scaffold[1];
            if ( $xpath =~ /for\((\w+)?\)/i ) {
                my $forN = $self->_forInterator();
                $xpath =~ s/for\((\w+)?\)/$forN/i;
            }
            if ( $xpath =~ /hit\((\d+)?\)/i ) {
                my $hitN = $self->{'total_hits_count'} + $1;
                $xpath =~ s/hit\((\d+)?\)/$hitN/i;
            }
            my $binding = $$scaffold[2];
            $sub_string = ${$TidyXML->asString($xpath)};  # This also sets m_found_context, for recursing.
            next SCAFFOLD unless $sub_string;
            if ( 'ARRAY' eq ref $binding ) {
                $sub_string = undef; # We don't need sub_string for recursing.
                $next_scaffold = $binding;
            } elsif ( defined $$scaffold[2] ) {
                my $i = 3;
                while ( $$scaffold[$i] and 'ARRAY' ne ref $$scaffold[$i] ) {
                    my $datParser = $$scaffold[$i];
                    $i += 1;
                    $sub_string = &$datParser($self, $hit, $sub_string);
                }
                $hit->plug_elem($binding, $sub_string);
                $total_hits_found = 1;
                next SCAFFOLD;
            } else {
                next SCAFFOLD;
            }

        } elsif ( $tag eq 'CLEANUP' )
        {
            my $i = 1;
            my $content = $TidyXML->asString();
            while ( $$scaffold[$i] and ('ARRAY' ne ref $$scaffold[$i]) ) {
                my $datParser = $$scaffold[$i];
                $i += 1;
                $content = &$datParser($self, $hit, $content);
            }
            $TidyXML->m_asString($content);
        }
        elsif ( $tag eq 'BOGUS' )
        {
            # Take back any hits at the header that are declared to be "bogus".
            my $bogusCount = $$scaffold[1];
            do { for ( 1..$bogusCount ) {
                last unless $total_hits_found > 0;
                $total_hits_found -= 1;
                shift @{$self->{cache}};
               }
            } if $bogusCount > 0;
            # Take back any hits at the footer that are declared to be "bogus".
            do { for ( 1..(-$bogusCount) ) {
                last unless $total_hits_found > 0;
                $total_hits_found -= 1;
                pop @{$self->{cache}};
               }
            } if $bogusCount < 0;
            next SCAFFOLD;
        }
        elsif ( $tag eq 'TRACE' )
        {
            my $x = ${$TidyXML->asString()};
            $x =~ s/\r//gs;
            print STDERR "TRACE:\n'$x'\n";
            $total_hits_found += $$scaffold[1];
        } elsif ( $tag eq 'CALLBACK' ) {
            &{$$scaffold[1]}($self, $hit, $TidyXML->asString(), $debug);
        } else {
            die "Unrecognized ScraperFrame option: '$tag'";
        }

        next SCAFFOLD unless $next_scaffold;
        $total_hits_found += $self->scraperRecurse(\$sub_string, $next_scaffold, $TidyXML, $hit, $debug);
    }
    return $total_hits_found;
}


sub newHit {
    my ($self, $resultType, $scraperFrame, $scraperDetailFrame) = @_;
    my $hit;
    if ( 'CODE' eq ref $resultType ) {
        $hit = &$resultType();
    } else {
#                eval "use WWW::Search::Scraper::Response$resultType";
#                if ( $@ ) {
#                    die "Can't load your Response module '$resultType': $@";
#                };
#        eval "use WWW::Search::Scraper::Response$resultType; \$hit = new WWW::Search::Scraper::Response$resultType(\$self)";
        $hit = new WWW::Search::Scraper::Response($self->{'scraperName'}, $scraperFrame, $scraperDetailFrame);
        die "Can't instantiate your Response module '$resultType': $!" unless $hit;
        $hit->_ScraperEngine($self);
    }
    return $hit;
}
sub touchUp {
    my ($self, $hit, $dat, $datParser) = @_;
}


# Returns the marked up text from the referenced string, as designated by the given tag.
# This algorithm extracts the contents of the first <$tag> element it encounters,
#   taking into consideration that it may contain <$tag> elements within it.
# It removes the marked text from the original string, strips off the markup tags,
#   and returns that result.
# (if wantarray, will return result and first tag, with brackets removed)
#
sub getMarkedText {
    my ($self, $tag, $content) = @_;
    
    my $eidx = 0;
    my $sidx = 0;
    my $depth = 0;

    while ( $$content =~ m-<(/)?$tag[^>]*?>-gsi ) {
        if ( $1 ) { # then we encountered an end-tag
            $depth -= 1;
            if ( $depth < 0 ) {
                # . . . then somehow we've stumbled into the midst of a table whose end-tag
                #   has just been encountered - let's be generous and start over.
                $eidx = 0;
                $sidx = 0;
                $depth = 0;
            }
            elsif ( $depth == 0 ) { # we've counted as many end-tags as start-tags; we're done!
                $eidx = pos $$content;
                last;
            }
        } else # we encountered a start-tag
        {
            $depth += 1;
            $sidx = length $` unless $sidx; 
        }
    }
    

    my $rslt = substr $$content, $sidx, $eidx - $sidx, '';
    $$content =~ m/./;
    $rslt =~ m-^<($tag[^>]*?)>(.*?)</$tag\s*[^>]*?>$-si;
    return ($2, $1) if wantarray;
    return $2;
}


sub addURL {
   my ($self, $hit, $dat) = @_;
   
   if ( $dat =~ m-<A\s+HREF="([^"]+)"[^>]*>-si )
   {
      my ($url) = new URI::URL($1, $self->{_base_url});
      $url = $url->abs();
      $hit->plug_url($url);
   } else
   {
      $hit->plug_url("Can't find HREF in '$dat'");
   }

   return trimTags($self, $hit, $dat);
}

# trimTags
#
# Strip tag clutter from $dat, in the context of $hit.
sub trimTags {
    my ($self, $hit, $dat) = @_;
   # This simply rearranges the parameter list from the datParser form.
    $dat =~ s/<br>/\n/gi;
    $dat =~ s/\r//gsi;
    return strip_tags($dat);
}

sub trimLFs { # Strip LFs, then tag clutter from $_;
    my ($self, $hit, $dat) = @_;
    $dat = $self->trimTags($hit, $dat);
    $dat =~ s/\s*\r?\n\s*//gs;
   # This simply rearranges the parameter list from the datParser form.
    return $dat;
}

sub trimLFLFs { # Strip double-LFs, then tag clutter from $_;
    my ($self, $hit, $dat) = @_;
    $dat = $self->trimTags($hit, $dat);
#    while ( 
        $dat =~ s/[\s]*\n([\s]*\n[\s]*)*/\n/gsi;
#         ) {}; # Do several times, rather than /g, to handle triple, quadruple, quintuple, etc.
   # This simply rearranges the parameter list from the datParser form.
    return $dat;
}

# XML::XPath seems to keep a blank, the attribute name, and the '=' sign in the result.
#       Is this standard XPath conventions? useless to us, though.
sub trimXPathAttr {
    my ($self, $hit, $dat) = @_;
    $dat =~ s/^ \w+?=(['"])(.*)\1$/$2/;
    return $dat;
}
# This does trimXPathAttr, then converts the result to an absolute URL.
sub trimXPathHref {
    my ($self, $hit, $dat) = @_;
    $dat =~ m/^ \w+?=(['"])(.*)\1$/;
    my ($url) = new URI::URL($2, $self->{_base_url});
    $url = $url->abs();
    $url = WWW::Search::Scraper::unescape_query($url);
    return $url;
}

sub removeScriptsInHTML {
    my ($self, $hit, $xml) = @_;
    
    # Strip out some regions that contain no information, but might be ill-formed output of "Tidy".
    my $removedScripts;
    for my $tag ( qw( script noscript ) ) {
        while ( $$xml =~ s-(<$tag.*?</$tag>)--si ) {
            $removedScripts .= $1;
        }
    }
    $self->{'removedScripts'} = \$removedScripts;
    
    return $xml;
}

# Remove everything between </HEAD> and <BODY> - this confuses TidyXML.
sub cleanupHeadBody {
    my ($self, $hit, $xml) = @_;
    $$xml =~ s-<html>(.*)<head>-<html><head>-gsi;
    $$xml =~ s-</head>(.*)<body>-</head><body>-gsi;
    $self->{'cleanedupHeadBody'} = \$1;
    return $xml;
}

# A null filter.
sub null { # Strip tag clutter from $_;
    my ($self, $hit, $dat) = @_;
    return $dat;
}

# Alternative name for the next_result() method for Scraper.
sub next_response {
    my $self = shift;
    $self->next_result(@_);
}

# Alternative name for the native_query() method for Scraper.
sub setup_query {
    my $self = shift;
    $self->native_query(@_);
}



# #######################################################################################
# Get the Next URL from a <form> on the page.
# Sometimes there's just a NEXT form, sometimes there's a PREV form and a NEXT form . . .
use HTML::Form;
sub findNextForm {
    my ($self, $hit, $dat) = @_;
    
    my $next_content = $dat;
    while ( my ($sub_content, $frm) = $self->getMarkedText('FORM', \$next_content) ) {
        last unless $sub_content;
        # Reconstruct the form that contains the NEXT data.
        my @forms = HTML::Form->parse("<form $frm>$sub_content</form>", $self->{'_base_url'});
        my $form = $forms[0];

        my $submit_button;
        for ( $form->inputs() ) {
            if ( $_->value() =~ m/Next/ ) {
                $submit_button = $_;
                last;
            }
        }
        if ( $submit_button ) {
            my $req = $submit_button->click($form); #
            return $req->uri();
        }
    }
    return undef;
}

# #######################################################################################
# Get the Next URL from a <form> on the page.
# Sometimes there's just a NEXT form, sometimes there's a PREV form and a NEXT form . . .
sub findNextFormInXML {
    my ($self, $hit, $dat) = @_;
    
    my $next_content = $dat;
    while ( my ($sub_content, $frm) = $self->getMarkedText('FORM', \$next_content) ) {
        last unless $sub_content;
        # Reconstruct the form that contains the NEXT data.
        my $asHTML = "<form $frm>$sub_content</form>";
        $asHTML =~ s-/>->-gs;
        my @forms = HTML::Form->parse($asHTML, $self->{'_base_url'});
        my $form = $forms[0];

        my $submit_button;
        for ( $form->inputs() ) {
            if ( $_->value() =~ m/Next/ ) {
                $submit_button = $_;
                last;
            }
        }
        if ( $submit_button ) {
            my $req = $submit_button->click($form); #
            return $req->uri();
        }
    }
    return undef;
}

sub unescape_query {
    # code stolen, and enhanced, from URI::Escape.pm.
    my @copy = @_;
    for (@copy) {
	    s/\+/ /g;
        s/\&amp;/&/g;
    	s/%([\dA-Fa-f]{2})/chr(hex($1))/eg;
    }
    return wantarray ? @copy : $copy[0];
}

1;

__END__
=pod

=head1 NAME

WWW::Search::Scraper - framework for scraping results from search engines.

=head1 SYNOPSIS

WWW::Search::Scraper('engineName');

=head1 DESCRIPTION

"Scraper" is a framework for issuing queries to a search engine, and scraping the
data from the resultant multi-page responses, and the associated detail pages.

As a framework, it allows you to get these results using only slight knowledge
of HTML and Perl. (All you need to know you can learn by reading this document.)

A Perl script, "Scraper.pl", uses Scraper.pm to investigate the "advanced search page"
of a search engine, issue a user specified query, and parse the results. (Scraper.pm can
be used by itself to support more elaborate searching Perl scripts.) Scraper.pl and Scraper.pm
have a limited amount of intelligent to figure out how to interpret the search page and
its results. That's where your human intelligence comes in. You need to supply hints to 
Scraper to help it find the right interpretation. And that is why you need some limited
knowledge of HTML and Perl.

=head1 MAJOR FEATURES

=over 4

=item Framing

A simple opcode based language makes describing the results and details pages of new engines easy,
and adapting to occasional changes in an existing engine's format simple.

=item Canonical Requests

A common Request container makes multiple search engine searches easy to implement, and 
automatically adapts to changes.

=item Canonical Response

A common Response container makes interpretation of results common among all search engines possible.
Also adapts easily to changes.

=item Post-filtering

Post-filtering provides a powerful client-based extension of the search capabilities to all search engines.

=back

=head1 BUILDING NEW SCRAPERS

=head2 FRONT-END

The front-end of Scraper is the part that figures out the search page and issues a query.
There are three ways to implement this end.

=head3 Three Ways to Issue Requests

=over 4

=item Use Sherlock

Apple Computer and Mozdev have established a standard format for accessing search engines named "Sherlock".
Via a "plugin" that describes the search engine's submission form and results pages, both Mac's and Mozilla
can access many search engines via a common interface. The Perl package C<WWW::Search::Sherlock> can read Sherlock
plugins and access those sites the same way.

This is simplest way to get up and running on a search engine. You just name the plugin, provide your query,
and watch it fly! You do not even need a sub-module associated with the search engine for this approach.
See C<WWW::Search::Sherlock> for examples of how this is done.

There are about a hundred plugins available at F<http://sherlock.mozdev.org/source/browse/sherlock/www/>,
contributed by many in the Open Source community.

There are a few drawbacks to this approach.

=over 4

=item Not all search engines have plugins.

Obviously, you are limited in this approach to those search engines that have plugins already built.
(You can build a plugin yourself, which is remarkably easy.  See F<http://www.apple.com/sherlock/plugindev.html>.)

=item The Sherlock standard is somewhat limited.

Two items in particular are lacking in the Sherlock standard. One, you can supply the value for only one of the
fields in the submission form. This still makes Sherlock pretty valuable, since it's rare that a search engine
will have more than one interesting field to fill in (and WWW::Search::Sherlock will allow you to set other field
values, even though that's not in the Sherlock standard.) Secondly, Sherlock makes no effort to load NEXT pages,
so your results will be limited to those appearing on the first response page.

=item The Sherlock standard does not parse all the interesting data from the response.

Sherlock parses only a half-dozen interesting fields from the data. Your client is left with the burden of parsing the
rest from the 'result' data field.

=item Sherlock parses only the first page of the response.

You should set the results-per-page to a high value. Sherlock will not go to the "Mext" page.

=item Not all Sherlock plugins are created equal.

You'll find that many of the plugins simply do not work. This is in spite of the fact that Sherlock includes
an automatic updating feature. But if you're updating to a version that doesn't work either, then you're kind of stuck!

=back

If you run into these limitations, then you may want to use one of the following approaches.

=item Load-and-parse the submission <FORM>

Scraper has the capability to automatically load the submission form, parse it, and create the query request.
All you do is supply the URL for the submission form, and the query parameter(s). Scraper loads and parses the form,
fills in the fields, and pushes the submit button for you. All you need to do is parse the results in the back-end.

=item Parse the <FORM> manually.

Go get the form yourself, and view the source. Editing the C<native_setup_search()> method of your search module,
find the URL of the ACTION= in the <FORM>, and plug that into your search module's C<{_option}{_base_url}> attribute.
Also provide the METHOD= value from the <FORM> into the C<<_http_method}> attribute.
You'll find the input fields in the <FORM> as <INPUT> elements. Supply values to 
these fields via the {'option'=>'value'} parameter of the C<next_result()> method, and you're on your way.

=back

See the EXAMPLES below for these two latter approaches.

=head3 prepare ( Canonical )

Anyway you go about executing a request, it is desirable to use a canonical interface to the user.
This allows the user to create one request, based on a "canon" of how requests should be formed,
that can be presented to any Scraper module and that module will understand what to do with it.
To make this work, each Scraper module must include a method for translating the canonical request
into a native request to their search engine. This is done with the prepare() method. If you are
going to write your own Scraper module, then you should write a prepare() method as well.

See the canonical request module F<WWW::Search::Scraper::Request> for a description of the canonical form,
and how the Scraper module uses it to generate a native form.
F<WWW::Search::Scraper> contains a prepare() method itself, which links up with the FieldTranslation class,
which will translate from a canonical field to one or more native fields.
It is based on a table lookup in so-called "tied-translation tables".
It also performs a "postSelect()" operation (via FieldTranslation) based on a table lookup in the same "tied-translation table".
See F<eg/setupLocations.pl> for an example of how this is used (in this case, for the canonical "locations" field).
See guidelines presented in F<WWW::Search::Scraper::Request> to get the best, most adaptable results.

=head2 BACK-END

The back-end of Scraper.pm receives the response from the search engine, handling the multiple pages
which it may be composed of, parses the results, and returns to the caller an appropriate Perl
representation of these results ("appropriate" means an array of hash tables of type WWW::Search::SearchResult).
Scraper.pl (or some other Perl client) further processes this data, or presents in some human readable form.

There are a few common ways in which search engines return their results in the HTML response.
These could be detected by Scraper.pm if it were intelligent enough, but unfortunately most
search engines add so much administrative clutter, banner ads, "join" options, and so forth
to the result that Scraper.pm usually needs some help in locating the real data.

The Scraper scripting language consists of both HTML parsing and string searching commands.
While a strict HTML parse should produce the most reliable results, as a practical matter it
is sometimes extremely difficult to grok just what the HTML structure of a response is (remember, these
reponses are composed by increasingly complex application server programs.) Therefore, it is necessary to provide
some hints as to where to start an interpretation by giving Scraper some kind of string searching
command.

The string searching commands (BODY, COUNT, NEXT) will point Scraper to approximately
the right place in the response page, while HTML parsing commands (TABLE, TR, TD, etc) will precisely
extract the exact data. There are also ways to to callbacks into your sub-module to do exactly the
type of parsing your engine requires.

Scraper performs its function by viewing the entire response page at once. Whenever a particular section
of the page is recognized, it will process that section according to your instructions, then discard the
recognized text from the page. It will repeat until no further sections are recognized.

We'll illustrate the exact syntax of this language in later examples, but 
the commands in this language include:

=over 4

=item BODY

This command directs Scraper to a specific section of the result page. Two parameters on the
BODY command give it a "start-string" and an "end-string". Scraper will search the result page
for these two strings, throw away everything before the "start-string" (including the start-string),
throw away everything after the "end-string" (including the end-string), then continue processing
with the remainder.

This is a quick way to get rid of a lot of administrative clutter. Either of the parameters is optional,
but one should be supplied or else it's a no-op.

Both start-string and end-string are treated as "regular expressions". If you don't know anything
about regular expressions, that's ok. Just treat them as strings that you would search for
in the result page; see the examples.

=item COUNT

This command provides a string by which Scraper will locate the "approximate count". It is a regular
expression (see comments above). See the examples for some self-explanatory illustrations.

=item NEXT

This command provides a string by which Scraper will be able to locate the "NEXT" button. You supply a string
that you expect to appear as text in the NEXT button anchor element (this is easier to find than you might expect.
A simple search for "NEXT" often does the trick.)

It is a regular expression (see comments above). See the examples for some self-explanatory illustrations.

=item TABLE, TR, DL or FORM

These commands are the HTML parsing commands. They use strict HTML parsing to zero in on areas containing actual data.

=item TD, DT and DD

These commands declare the locations of the actual data elements. Some search engines use <TD> elements to
present data, some use <DT> and <DD> elements.
(Some use neither, which is why you'll need to use C<DATA> or C<REGEX> on these.)
The first parameter on the TD, DT or DD command names the field in which the garnered data will be placed.
A second parameter provides a reference to optional subroutine for further processing of the data.

=item DATA

DATA is like BODY in that it specifies a specific area of the document according to start and end strings.
It's different in that it will take that text and store it as result data rather than further processing it.

=item A and AN

Often, data and a hyperlink (to a detail page, for instance) are presented simultaneously in an "anchor" element.
Two parameters on the A command name the fields into which the garnered link and data will be placed.

There are two forms of the C<A> command since some loosely coded HTML will supply the hyperlink without the quote marks.
This creates some disturbing results sometimes, so if your data is in an anchor where the HREF is
provided without quotes, then the C<AN> operation will parse it more reliably.

=item XPath

Find significant data by specifying the XPath to that data's region. 
This requires the TidyXML method to convert HTML to well-formed XML.

    [ 'XPath', 'font/a/@href', 'url', \&trimXPathHref ]

This finds the HREF attribute of the anchor in the <font> element, processes it with the trimXPathHref function,
then assigns it to the 'url' response field.

See F<http://www.w3.org/TR/xpath> to learn how to code "location paths" in the XPath language.

See FlipDog.pm and Dogpile.pm for examples of 'XPath' in Scraper engines.

=item TidyXML

Instead of 'HTML', use 'TidyXML' to convert the HTML to well-formed XML before processing.
This changes the structure slightly, but especially it makes it accessible to the XPath method for locating data.

    [ 'TidyXML', \&cleanupHeadBody, \&removeScriptsInHTML, [ [ frame ] ] ]

The functions (cleanupHeadBody() and removeScriptsInHTML) are executed on the HTML before handing it to TidyXML.
These two functions are handy, in that TidyXML doesn't like stuff in </HEAD>. . .<BODY> (which some engines produce),
and scripts in some engines results often contain unrecognized entities, but are otherwise useless content to us.    

See FlipDog.pm and Brainpower (detail page) for examples.

=item HIT*

This command declares that the hits are about to be coming!
There are several formats for this command; they declare the hit is here, the type of the hit, and how to parse it.
An optional second parameter names the type of WWW::Search::Scraper::Response class will encapsulate the response.
This parameter may be a string, naming the class ('Job', or 'Apartment', for instance), or it may be a reference
of a subroutine that instantiates the response (as if C<new WWW::Search::Scraper::Response::Job>, for instance).
(You may override this with a 'scraperResultType' option on Scraper->new().)
The last parameter (being second or third parameter, depending if you declare a hit type) specifies a Scraper script,
as described here, for parsing all the data for one complete record.
HIT* will process that script, instantiate a Response object, stash the results into it, discarding the parsed text,
and continuing until there is no more parsable data to be found.

=item FOR

For iteration - specify a interator name, and a "for" condition in "i..j" format.
The contained frame is executed for each value in the range "i" to "j".
The current iteration can be substituted into XPath strings using the function "for(iteratorName)".

    [ 'FOR', 'myInterator', '3..7', [ [ frame ] ] ]

See FlipDog.pm for an example


=item REGEX

Well, this would be self-explanatory if you knew anything about regular expressions, you dope! Oh, sorry . . .

The first parameter on the REGEX command is a regular expression. The rest of the parameters are a list naming which
fields the matched variables of this regex ($1, $2, $3, etc) will be placed.

=item CALLBACK

CALLBACK is like DATA, in that it selects a section of the text based on start and end strings
(which are treated as regular expressions). Then, rather than storing the data away, it will
call a subroutine that you have provided in your sub-module. Your subroutine may decide to store
some data into the hit; it can decide whether to discard the text after processing, or to keep
it for further processing; it can decide whether the data justifies being a hit or not (unless some
parsing step finds this justification, then the parsing will stop. TD, DATA, REGEX, et.al. will do that,
but if you are using CALLBACK, you might not need the other data harvesting operations at all, so your
callback subroutine must "declare" this justification when appropriate).

See the code for C<WWW::Search::Sherlock> for an illustration of how this works. Sherlock uses this
method for almost all its parsing. A sample Sherlock scraper frame is also listed below in the EXAMPLES.

=item RESIDUE

After each of the parsing commands is executed, the text within the scope of that command is discarded.
In the end, there may be some residue left over. It may be convenient to put this residue in some field so
you can see if you have missed any important data in your parsing.

=item BOGUS

Even after carefully designing a scraper frame, the HIT* section's parsing sometimes results
in extra hits at the beginning or end of the page. A positive value for BOGUS clips that 
many responses from the beginning of the hit list; a negative value for BOGUS pops that 
many resonses off the end of the list.

=item TRACE

TRACE will print the entire text that is currently in context of the Scraper parser, to STDERR.

=item HTML

HTML is simply a command that you will place first in your script. Don't ask why, just do it.

=back 4

=head2 SYNTAX

Scraper accepts its command script as a reference to a Perl array. You don't need to know how to build
a Perl array; just follow these simple steps.

As noted above, every script begins with an HTML command

[ 'HTML' ]

You put the command is square brackets, and the name of the command in single quotes.
HTML will have a single parameter, which is a reference to a Scraper script (in other words, another array).

[ 'HTML', [ ...Scraper script... ] ]

(You can see this is going to get messy with all these square brackets.)

Suppose we want to parse for just the NEXT button.

    [ 'HTML', 
              [
                     [ 'NEXT', '<B>Next' ]
              ]
    ]

The basic syntax is, a set of square brackets, and a command name in single quotes, to designate a command.
Following that command name may be one or two parameters, and following those parameters may be another list
of commands. The list is within a set of square brackets, so often you will see two opening brackets together.
At the end you will see a lot of closing brackets together (get used to counting brackets!).

=head2 EXAMPLES

=over 4

=item CraigsList

CraigsList.com produces a relatively simple result page. Unfortunately, it does not use any of the
standard methods for presenting data in a table, so we are required to use the REGEX method for
locating data. 

Most search engines will not require you to use REGEX. We've used CraigsList here not to illustrate REGEX,
but to illustrate the structure of the Scraper scripting syntax more clearly.
Just ignore the REGEX command in this script; realize that it parses a data string and puts the
results in the fields named there.

    [ 'HTML', 
       [
          [ 'BODY', '</FORM>', '' ,
             [
                [ 'COUNT', 'found (\d+) entries'] ,
                  [ 'HIT*' ,
                    [
                       [ 'REGEX', '(.*?)-.*?<a href=([^>]+)>(.*?)</a>(.*?)<.*?>(.*?)<', 
                                   'date',  'url', 'title', 'location', 'description' ]
                    ]
                ]
             ]
          ]
       ]
    ]

This tells Scraper to skip ahead, just past the first "</FORM>" string (it's only a coincidence that this
string is also an HTML end-tag.) In the remainder of the result page,
Scraper will find the appoximate COUNT in the string "found (\d+) entries" (the '\d+' means to find at least one digit),
then the HITs will be found by applying the regular expression repeatedly to the rest.

=item JustTechJobs

JustTechJobs.com presents one of the prettiest results pages around. It is nice and very deeply structured
(by Lotus-Domino, I think), which makes it very difficult to figure out manually. However, a few simple short-cuts
produce a relatively simple Scraper script.


    [ 'HTML', 
       [   
          [ 'COUNT', '\d+ - \d+ of (\d+) matches' ] ,
          [ 'NEXT', 1, '<b>Next ' ] ,
          [ 'HIT*' ,
             [
                [ 'BODY', '<input type="checkbox" name="check_', '',
                   [  [ 'A', 'url', 'title' ] ,
                      [ 'TD' ],
                      [ 'TABLE', '#0',
                         [
                            [ 'TD' ] ,
                            [ 'TD', 'payrate' ],
                            [ 'TD' ] ,
                            [ 'TD', 'company' ],
                            [ 'TD' ] ,
                            [ 'TD', 'locations' ],
                            [ 'TD' ] ,
                            [ 'TD', 'description' ]
                         ]
                      ]
                   ]
                ]
             ]
          ]
       ]
    ]

Note that the initial BODY command, that was used in CraigsLIst, is optional.
We don't use it here since most of JustTechJobs' result page is data, with very little administrative clutter.

We pick up the COUNT right away, with a simple regular expression. Then the NEXT button is located and stashed.
The rest of the result page is rich with content, so the actual data starts right away.

Because of the extreme complexity of this page (due to its automated generation) the simplest way to locate a data
record is by scanning for a particular string. In this case, the string '<input type . . .check_' identifies a checkbox
that starts each data record on the JustTechJobs page. We put this BODY command inside of a HIT* so that it is 
executed as many times as required to pick up all the data records on the page.

Within the area specified by the BODY command, you will find a table that contains the data.
The first parameter of the TABLE command, '#0', means to skip zero tables and to just read the first one.
The second parameter of the TABLE is a script telling Scraper how to interpret the data in the table.
The primitive data in this table is contained in TD elements, as are labels for each of the data elements.
We throw away those labels by specifying no destination field for the data.

The page, as composed by Lotus-Domino, literally consists of a form, containing several tables, 
one of which contains another table, which in turn contains data elements which are themselves
two tables in which each of the job listings are presented in various forms (I think). 
Given such a complex page, this Scraper script is remarkably simple for interpreting it.

=item DICE

Ok, I know you all wanted to know what DICE.com looks like. Well, here it is:
                            
    [ 'HTML', 
       [  
          [ 'BODY', ' matching your query', '' ,
             [  
                [ 'NEXT', 1, '<img src="/images/rightarrow.gif" border=0>' ]
               ,[ 'COUNT', 'Jobs [-0-9]+ of (\d+) matching your query' ]
               ,[ 'HIT*' ,
                   [  
                      [ 'DL',
                         [
                            [ 'DT', 'title', \&addURL ] 
                           ,[ 'DD', 'location', \&touchupLocation ]
                           ,[ 'RESIDUE', 'residue' ]
                         ]
                      ]
                   ]
                ]
             ] 
          ]  
       ]
    ]

We'll leave this as an exercise for the reader (note that this is the "brief" form of the response page.)

=item Sherlock

Now that you're fairly well-versed in Scraper frame operations syntax, we'll use a fairly complex frame,
automatically generated by C<WWW::Search::Sherlock>, to illustrate how Sherlock uses the Scraper framework.

If you point Sherlock to the Yahoo plugin, it will generate the following Scraper frame to parse the result page.

        [
          'HTML',
          [
            [
              'CALLBACK', \&resultList,
              'Inside Yahoo! Matches',
              'Yahoo! Category Matches',
              [
                [
                  'HIT*',
                  [
                    [
                      'CALLBACK', \&resultItem,
                      '<b>',
                      '<br>',
                      [
                        [
                          'CALLBACK',
                          \&resultData,
                          '<b>',
                          ':</b>',
                          'result_name'
                        ]
                      ],
                      undef
                    ]
                  ],
                  'result'
                ]
              ]
            ],
            [
              'CALLBACK',
              \&resultList,
              'Yahoo! Category Matches',
              'Yahoo! News Headline Matches',
              [
                [
                  'HIT*',
                  [
                    [
                      'CALLBACK', \&resultItem,
                      '<dt><font face=arial size=-1>',
                      '</a></li><p></dd>',
                      [
                        [
                          'CALLBACK', \&resultData,
                          '<li>',
                          '</a></li><p></dd>',
                          'result_name'
                        ]
                      ],
                      undef
                    ]
                  ],
                  'category'
                ]
              ]
            ]
          ]
        ]

You'll notice that there are three callback functions in here (six invocations). 
These are named after the parts-of-speech specified in the Sherlock technotes.
These callback functions will process the data a little differently than the standard Scraper
functions would. 

In Sherlock, for instance, the start and end strings are considered part
of the data, so throwing them away causes unfortunate results. Our callbacks handle the data
more in the way that Sherlock's creators intended. 

'resultList' corresponds to Scraper's BODY, 'resultItem' corresponds to Scraper's TABLE, and 'resultData'
corresponds to Scraper's DATA. The next two parameters of each CALLBACK operation indicate the start and
end strings for that callback function. (A fourth parameter allows you to pass more specific information
from the Scraper frame to the callback function, as desired.) 
Of course, these callback functions then handle the data in the "Sherlock way", rather than the "Scraper way".

Note that the start string for the second resultList is the same as the end string of the first resultList.
This is but one illustration of how Sherlock handles things differently than Scraper. But by using the
CALLBACK operation, just about any type of special treatment can be created for Scraper.

We refer you to the code for C<WWW::Search::Sherlock> for further education on how to compose your own CALLBACK functions.

=back

=head1 DEPENDENCIES

In addition to F<WWW::Search>, Scraper depends on these non-core modules in order to support the
translation of requests from canonical forms to native forms.

=over 8

=item F<Tie::Persistent>

=item F<Storable>

=back

The Scraper modules that do table driven field translations (from canonical requests to native requests) will have
files included in their package representing the translation table in Storable format. The names of these files are
<ScraperModuleName>.<requestType>.<canonicalFieldName>. E.G., Brainpower.pm owns a translation table for the 'location'
field of the canonical Request::Job module; it is named C<Brainpower.Job.location> . 

See F<WWW::Search::Scraper::Request.pm> for more information on Translations.

=head1 AUTHOR

Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (C) 2001-2002 Glenn Wood. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

