=pod

=head1 NAME

WWW::Search::Scraper - framework for scraping results from search engines.

=head1 SYNOPSIS

WWW::Search::Scraper('engineName');

=head1 DESCRIPTION

"Scraper" is a framework for issuing queries to a search engine, and scraping the
data from the resultant multi-page responses.

As a framework, it allows you to get these results using only slight knowledge
of HTML and Perl. (All you need to know you can learn by reading this document.)

A Perl script, "Scraper.pl", uses Scraper.pm to investigate the "advanced search page"
of a search engine, issue a user specified query, and parse the results. (Scraper.pm can
be used by itself to support more elaborate searching Perl scripts.) Scraper.pl and Scraper.pm
have a limited amount of intelligent to figure out how to interpret the search page and
its results. That's where your human intelligence comes in. You need to supply hints to 
Scraper to help it find the right interpretation. And that is why you need some limited
knowledge of HTML and Perl.

=head2 FRONT-END

The front-end of Scraper is the part that figures out the search page and issues a query.
There are three ways to implement this end.

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

=item HIT*

This command declares that the hits are about to be coming!
The first (and only) parameter of the HIT* command specifies a Scraper script, as described here,
 for parsing all the data for one complete record.
HIT* will process that script, stashing the record away, discarding the parsed text, and continuing until
there is no more data to be found the corresponding text.

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

=head1 AUTHOR

Glenn Wood, C<glenwood@alumni.caltech.edu>.

=head1 COPYRIGHT

Copyright (C) 2001 Glenn Wood. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


####################################################################################
####################################################################################
####################################################################################
####################################################################################
package WWW::Search::Scraper;

use strict;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
@EXPORT = qw();
@EXPORT_OK = qw();
@ISA = qw(WWW::Search Exporter);
$VERSION = sprintf("%d.%02d", q$Revision: 1.43 $ =~ /(\d+)\.(\d+)/);

use Carp ();
use WWW::Search( qw(strip_tags) );
require WWW::SearchResult;
@EXPORT_OK = qw(escape_query unescape_query generic_option 
                strip_tags trimTags trimLFs trimLFLFs
                @ENGINES_WORKING addURL);


sub new {
    my ($class, $subclass, $searchName) = @_;
    
    my $self;
    if ( $subclass =~ m-^\.\.[\/](.*)$- ) { # Allow the form "../name" to indicate
       $self = new WWW::Search($1);       # a WWW::Search backend. Also see "Some 
    } else {                                #  searchers are not scrapers", below.
        $self = new WWW::Search("Scraper::$subclass");
    }

    $self->{'scraperQF'} = 0; # Explicitly declare 'scraperQF' as the deprecated mode.
    $searchName = $subclass unless $searchName;
    $self->{'scraperName'} = $searchName;
    return $self;
}



sub generic_option 
{
    my ($option) = @_;
    return 1 if $option =~ /^scrape/;
    return WWW::Search::generic_option($option);
}

sub native_setup_search
{
    my $self = shift;
    
    my @qType = @{$self->{'_options'}{'scraperQuery'}};
    return $self->native_setup_search_NULL(@_) unless @qType;

    for ( $qType[0] ) {
        m/SHERLOCK/ && do { $self->native_setup_search_SHERLOCK(@_); last };
        m/FORM/     && do { $self->native_setup_search_FORM(@_); last };
        m/QUERY/    && do { $self->native_setup_search_QUERY(@_); last };
        m/POST/     && do { $self->{'_http_method'} = 'POST';
                            $self->native_setup_search_QUERY(@_); last };
        die "Invalid mode in WWW::Search::Scraper - '$_'\n";
    }
}



sub native_setup_search_SHERLOCK
{
    die "Unimplemented mode in WWW::Search::Scraper - 'SHERLOCK'\n";
}


sub native_setup_search_FORM
{
    die "Unimplemented mode in WWW::Search::Scraper - 'FORM'\n";
}


sub native_setup_search_QUERY
{
    my($self, $native_query, $native_options_ref) = @_;
    my @qType = @{$self->{'_options'}{'scraperQuery'}};
    
    $self->user_agent('user');
    $self->{_next_to_retrieve} = 0;
    
    my $url = $qType[1];
    if ( ref $url ) {
        $self->{'_base_url'} = &$url($self, $native_query, $native_options_ref);
    } else {
        $self->{'_base_url'} = $url;
    }
    unless ( $self->{'_base_url'} ) {
        print STDERR "No base url was specified by ".ref($self).".pm, so no search is possible.\n";
        undef $self->{'_next_url'};
        return undef;
    }
    $self->{'_http_method'} = 'GET' unless $self->{'_http_method'};

    my %inputsHash = %{$qType[2]};
    my %optionHash = %{$qType[3]};

    my($options_ref) = $self->{_options};
    if (defined($native_options_ref)) {
    	# Copy in new options.
    	foreach (keys %$native_options_ref) {
    	    $options_ref->{$_} = $native_options_ref->{$_} if defined $native_options_ref->{$_};
    	};
    };
    $self->{_debug} = $options_ref->{'search_debug'};
    $self->{_debug} = 2 if ($options_ref->{'search_parse_debug'});
    $self->{_debug} = 0 if (!defined($self->{_debug}));
    
    # Process the options.
    $self->cookie_jar(HTTP::Cookies->new()) if $optionHash{'cookies'};
    foreach (sort keys %optionHash) {
        $self->{'_scraperOptions'}{$_} = $optionHash{$_};
    };
    
    
    # Process the inputs.
    # (Now in sorted order for consistency regarless of hash ordering.)
    my $options = "$inputsHash{'scraperQuery'}=$native_query";
    foreach (sort keys %$options_ref) {
    	# printf STDERR "option: $_ is " . $options_ref->{$_} . "\n";
    	next if (generic_option($_));
        $options .= "&$_=$options_ref->{$_}";
    };
    
    $self->{'_next_url'} = $self->{'_base_url'}.$options;
    print STDERR $self->{_base_url} . "\n" if ($self->{_debug});
}


# This one handles the deprecated Scraper::native_setup_search()
sub native_setup_search_NULL
{
    my($self, $native_query, $native_options_ref) = @_;
    
    my $subJob = 'Perl';
    $self->user_agent('user');
    $self->{_next_to_retrieve} = 0;
    if (!defined($self->{_options})) {
	$self->{_options} = {
#	    'search_url' => 'http://www.defaultdomain.com/plus-cgi-bin/and-cgi-program-name'  SHOULD BE PASSED IN AS AN OPTION.
        };
    };
    $self->{'_http_method'} = 'GET';        # SHOULD BE PASSED IN AS AN OPTION; this is the default.
#    $self->{'_options'}{'scrapeFrame'} =  []; SHOULD BE PASSED IN AS AN OPTION.
 
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
    $self->{_debug} = $options_ref->{'search_debug'};
    $self->{_debug} = 2 if ($options_ref->{'search_parse_debug'});
    $self->{_debug} = 0 if (!defined($self->{_debug}));
    
    # Finally figure out the url.
    $self->{_base_url} = 
	$self->{_next_url} =
            	$self->{_options}{'search_url'} .
        	    "?" . $options .
            	"KEYWORDS=" . $native_query;

    print STDERR $self->{_base_url} . "\n" if ($self->{_debug});
}



sub native_retrieve_some
{
    my ($self) = @_;
    
    # fast exit if already done
    return undef if ( !defined($self->{_next_url}) );
    
    # get some
     if ( $self->{_debug} ) {
         my $obj = ref $self;
         print STDERR "$obj::native_retrieve_some: fetching " . $self->{_next_url} . "\n";
     }
    my $method = $self->{'_http_method'};
    $method = 'GET' unless $method;
    my $response = $self->http_request($method, $self->{_next_url});
    $self->{'_last_url'} = $self->{'_next_url'}; $self->{'_next_url'} = undef;
    $self->{response} = $response;
    
    return undef unless $response->is_success;

    my $hits_found = $self->scrape($response->content(), $self->{_debug});

    # sleep so as to not overload the engine
    $self->user_agent_delay if ( defined($self->{_next_url}) );
    
    return $hits_found;
}



# Public
sub scrape { my ($self, $content, $debug) = @_;
   return scraper($self, $self->{'_options'}{'scrapeFrame'}[1], \$content, undef, $debug);
}

# private
sub scraper { my ($self, $scaffold_array, $content, $hit, $debug) = @_;
	# Here are some variables that we use frequently done here.
    my $total_hits_found = 0;
    
    my ($sub_content, $next_scaffold);


SCAFFOLD: for my $scaffold ( @$scaffold_array ) {
        my $tag = $$scaffold[0];

       print "TAG: $tag\n" if $debug > 1;

        # 'HIT*' is special since it has pre- and post- processing (adding the hits to the hit-list).
        # All other tokens simply process data as it moves along, then they're done,
        #  so they will do a set up, then pass along to recurse on scraper() . . .
        if ( 'HIT*' eq $tag )
        {
            my $hit;
            do 
            {
                if ( $hit )
                {
                    push @{$self->{cache}}, $hit;
                    $total_hits_found += 1;
                }
                $hit = $self->newHit();
                $hit->{'searchObject'} = $self;
            } while ( $self->scraper($$scaffold[1], $content, $hit, $debug) );
            next SCAFFOLD;
        }
    
        elsif ( 'BODY' eq $tag )
        {  
            $sub_content = '';
            if ( $$scaffold[1] and $$scaffold[2] ) {
                $$content =~ s-$$scaffold[1](.*?)$$scaffold[2]--si; # Strip off the adminstrative clutter at the beginning and end.
                $sub_content = $1;
            } elsif ( $$scaffold[1] ) {
                $$content =~ s-$$scaffold[1](.*)$-$1-si; # Strip off the adminstrative clutter at the beginning.
                $sub_content = $1;
            } elsif ( $$scaffold[2] ) {
                $$content =~ s-^(.*?)$$scaffold[2]-$1-si; # Strip off the adminstrative clutter at the end.
                $sub_content = $1;
            } else {
                next SCAFFOLD;
            }
            $next_scaffold = $$scaffold[3];
        }
    	
        elsif ( 'CALLBACK' eq $tag ) {
            ($sub_content, $next_scaffold) = &{$$scaffold[1]}($self, $hit, $content, $scaffold, \$total_hits_found);
            next SCAFFOLD unless $next_scaffold;
        }
    	
        elsif ( 'DATA' eq $tag )
        {
            $sub_content = '';
            if ( $$scaffold[1] and $$scaffold[2] ) {
                $$content =~ s-$$scaffold[1](.*?)$$scaffold[2]--si;
                $sub_content = $1;
            } else {
                next SCAFFOLD;
            }
            my $binding = $$scaffold[3];
            $hit->_elem($binding, $sub_content);
            $total_hits_found = 1;
            next SCAFFOLD;
        }
    	
        elsif ( 'COUNT' eq $tag )
    	{
            $self->approximate_result_count(0);
    		if ( $$content =~ m/$$scaffold[1]/si )
    		{
    			print STDERR  "approximate_result_count: '$1'\n" if $debug;
    			$self->approximate_result_count ($1);
                next SCAFFOLD;
    		}
            else {
                print STDERR "Can't find COUNT: '$$scaffold[1]'\n" if $debug;
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
                $self->{'_next_url'} = &$datParser($self, $hit, $$content);                
                print STDERR  "NEXT_URL: $self->{'_next_url'}\n" if $debug;
                next SCAFFOLD;
            }
            else
            {
                # A simple regex will not work here, since the "next" string may often
                # appear even when there's no <A>...</A> surrounding it. The problem occurs
                # when there is a <A>...</A> preceding it, *and* following it. Simple regex's
                # will find the first anchor, even though it's not the HREF for the "next" string.
                my $next_url_button = $$scaffold[2];
                print STDERR  "next_url_button: $next_url_button\n" if $debug;
                my $next_content = $$content;
                while ( my ($sub_content, $url) = $self->getMarkedText('A', \$next_content) ) 
                {
                    last unless $sub_content;
                    if ( $sub_content =~ m-$next_url_button-si )
                    {
                        $url =~ s-A\s+HREF=--si;
                        $url =~ s-^'(.*?)'\s*$-$1-si unless $url =~ s-^"(.*?)"\s*$-$1-si;
                        my $datParser = $$scaffold[3];
                        $datParser = \&WWW::Search::Scraper::null unless $datParser;
                        my $url = new URI::URL(&$datParser($self, $hit, $url), $self->{_base_url});
                        $url = $url->abs;
                        $self->{'_next_url'} = $url;
                        print STDERR  "NEXT_URL: $url\n" if $debug;
                        next SCAFFOLD;
                    }
                }
            }
            next SCAFFOLD;
        }

        elsif ( 'HTML' eq $tag )
        {
            $$content =~ m-<HTML>(.*)</HTML>-si;
            $sub_content = $1;
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
                    my $x = $self->getMarkedText($tag, $content); # and throw it away.
    			}
                $next_scaffold = $$scaffold[2];
            }
            else {
                print STDERR  "elmName: $elmName\n" if $debug;
                $next_scaffold = $$scaffold[2];
                die "Element-name form of <$tag> is not implemented, yet.";
            }
            next SCAFFOLD unless $sub_content = $self->getMarkedText($tag, $content);
        }
    	elsif ( $tag =~ m/^(TD|DT|DD|DIV)$/ )
        {
            next SCAFFOLD unless $sub_content = $self->getMarkedText($tag, $content); # and throw it away.
#    		next SCAFFOLD unless ( $$content =~ s-(<$tag\s*[^>]*>(.*?)</$tag\s*[^>]*>)--si );  $sub_content = $2;
    		$next_scaffold = $$scaffold[1];
            if ( 'ARRAY' ne ref $next_scaffold  ) # if next_scaffold is an array ref, then we'll recurse (below)
            {
               my $binding = $next_scaffold;
               my $datParser = $$scaffold[2];
               print STDERR  "raw dat: '$sub_content'\n" if $debug;
               if ( $debug ) { # print ref $ aways does something screwy
                  print STDERR  "datParser: ";
                  print STDERR  ref $datParser;
                  print STDERR  "\n";
               };
               $datParser = \&WWW::Search::Scraper::trimTags unless $datParser;
               print STDERR  "binding: '$binding', " if $debug;
               print STDERR  "parsed dat: '".&$datParser($self, $hit, $sub_content)."'\n" if $debug;
                if ( $binding eq 'url' )
                {
                    my $url = new URI::URL(&$datParser($self, $hit, $sub_content), $self->{_base_url});
                    $url = $url->abs;
                    $hit->add_url($url);
                } 
                elsif ( $binding) {
                    $hit->_elem($binding, &$datParser($self, $hit, $sub_content));
                }
                $total_hits_found = 1;
                next SCAFFOLD;
            }
        }
        elsif ( 'A' eq $tag ) 
        {
            my $lbl = $$scaffold[1];
            if ( $$content =~ s-<A\s+HREF="([^"]+)"[^>]*>(.*?)</A>--si )
            {
                print "<A> binding: $$scaffold[2]: '$2', $$scaffold[1]: '$1'\n" if $debug;
                my $datParser = $$scaffold[3];
                $datParser = \&WWW::Search::Scraper::trimTags unless $datParser;
                $hit->_elem($$scaffold[2], &$datParser($self, $hit, $2));

               my ($url) = new URI::URL($1, $self->{_base_url});
               $url = $url->abs;
               if ( $lbl eq 'url' ) {
                    $hit->add_url($url);
               }
               else {
                   $hit->_elem($lbl, $url);
               }
               $total_hits_found = 1;
            }
            next SCAFFOLD;
        }
        elsif ( 'AN' eq $tag ) 
        {
            my $lbl = $$scaffold[1];
            if ( $$content =~ s-<A\s+HREF=([^>]+)>(.*?)</A>--si )
            {
                print "<A> binding: $$scaffold[2]: '$2', $$scaffold[1]: '$1'\n" if $debug;
                
                my $datParser = $$scaffold[3];
                $datParser = \&WWW::Search::Scraper::trimTags unless $datParser;
                $hit->_elem($$scaffold[2], &$datParser($self, $hit, $2));

               my ($url) = new URI::URL($1, $self->{_base_url});
               $url = $url->abs;
               if ( $lbl eq 'url' ) {
                    $hit->add_url($url);
               }
               else {
                   $hit->_elem($lbl, $url);
               }
               $total_hits_found = 1;
            }
            next SCAFFOLD;
        }
        elsif ( 'REGEX' eq $tag ) 
        {
            my @ary = @$scaffold;
            shift @ary;
            my $regex = shift @ary;
            if ( $$content =~ s/$regex//si )
            {
                my @dts = ($1,$2,$3,$4,$5,$6,$7,$8,$9);
                for ( @ary ) 
                {
                    if ( $_ eq '' ) {
                        shift @dts;
                    }
                    elsif ( $_ eq 'url' ) {
                        my $url = new URI::URL(shift @dts, $self->{_base_url});
                        $url = $url->abs;
                        $hit->add_url($url);
                    } 
                    else {
                        $hit->_elem($_, $self->trimTags($hit, shift @dts));
                    }
                }
                $total_hits_found = 1;
            }
            next SCAFFOLD;
        } elsif ( $tag eq 'RESIDUE' )
        {
            $sub_content = $$content;
            my $binding = $$scaffold[1];
            my $datParser = $$scaffold[2];
            $datParser = \&WWW::Search::Scraper::null unless $datParser;
            $hit->_elem($binding, &$datParser($self, $hit, $sub_content));
            next SCAFFOLD;
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
            my $x = $$content;
            $x =~ s/\r//gs;
            print "TRACE:\n'$x'\n";
            $total_hits_found += $$scaffold[1];
        } elsif ( $tag eq 'CALLBACK' ) {
            &{$$scaffold[1]}($self, $hit, $content, $debug);
        } else {
            die "Unrecognized tag: '$tag'";
        }

        # So it's all set up to recurse to the next layer - - -
        $total_hits_found += $self->scraper($next_scaffold, \$sub_content, $hit, $debug);
    }
    return $total_hits_found;
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
      $url = $url->abs;
      $hit->add_url($url);
   } else
   {
      $hit->add_url("Can't find HREF in '$dat'");
   }

   return trimTags($self, $hit, $dat);
}


sub trimTags { # Strip tag clutter from $_;
    my ($self, $hit, $dat) = @_;
   # This simply rearranges the parameter list from the datParser form.
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



use WWW::Search::Scraper::Response;
sub newHit {
    my $self = new WWW::Search::Scraper::Response;
    return $self;
}

{ package WWW::Search;
sub getName {
   return $_[0]->{'scraperName'};
}

}



{
    package LWP::UserAgent;

# Dice always redirects the first query page via 302 status code.
# BAJobs frequently (but not always) redirects via 302 status code.
# We need to tell LWP::UserAgent that it's ok to redirect on Dice and BAJobs.
sub redirect_ok
{
    # draft-ietf-http-v10-spec-02.ps from www.ics.uci.edu, specify:
    #
    # If the 30[12] status code is received in response to a request using
    # the POST method, the user agent must not automatically redirect the
    # request unless it can be confirmed by the user, since this might change
    # the conditions under which the request was issued.

    my($self, $request) = @_;
    return 1 if $request->uri() =~ m-jobsearch\.dice\.com/jobsearch/jobsearch\.cgi-i;
    return 1 if $request->uri() =~ m-www\.bajobs\.com/jobseeker/searchresults\.jsp-i;
    return 1 if $request->uri() =~ m-\.techies\.com/Common-i;
    return 0 if $request->method eq "POST";
    1;
}
}



1;
