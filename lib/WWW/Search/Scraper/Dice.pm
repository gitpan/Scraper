
package WWW::Search::Scraper::Dice;
use strict;
use vars qw($VERSION @ISA);
@ISA = qw(WWW::Search::Scraper);
$VERSION = sprintf("%d.%02d", q$Revision: 1.17 $ =~ /(\d+)\.(\d+)/);

use WWW::Search::Scraper(qw(1.48 generic_option trimTags addURL));
use WWW::Search::Scraper::FieldTranslation;

my $scraperRequest = 
   { 
      'type' => 'POST'       # Type of query generation is 'POST'
     ,'redirectMethod' => 'GET' # Let me quote W3C HTTP 1.1 Specification (at http://www.w3.org/Protocols/rfc2068/rfc2068)
                                #      Note: When automatically redirecting a POST request after receiving
                                #     a 302 status code, some existing HTTP/1.0 user agents will
                                #     erroneously change it into a GET request.
                                # Yet Dice.com *relies* on the browser to change it to 'GET', otherwise it don't work!
                                # I guess that's what's so nice about standards - there's so many to choose from!

      # This is the basic URL on which to build the query.
     ,'url' => 'http://jobsearch.dice.com/jobsearch/jobsearch.cgi?'
      # This is the Scraper attributes => native input fields mapping
      ,'nativeQuery' => 'query'
      ,'defaultRequestClass' => 'Job'
      ,'nativeDefaults' =>
           {
               'Search.x' => 1,'Search.y' => 1,
               'banner' => '0',
               'brief' => 'true',
               'method' => 'bool',
               'taxterm' => '',
               'state' => 'ALL',         # or two character abbreviation(s)
               'acode' => '',            # multiple acode INPUT fields
               'daysback' => 30,         # (1, 2, 7, 10, 14, 21, 30)
               'num_per_page' => 50,     # (10, 20, 30, 40, 50) 
               'num_to_retrieve' => 2000 # (100, 200, 300, 400, 500, 600, 2000)
           }
     ,'fieldTranslations' =>
             {
                 '*' =>
                     {    'skills'    => 'query'
                         ,'locations' => new WWW::Search::Scraper::FieldTranslation('Dice', 'Job', 'locations')
                         ,'*'             => '*'
                     }
             }
      # Some more options for the Scraper operation.
     ,'cookies' => 0
   };

my $scraperFrame =
      [ 'HTML', 
         [  
            [ 'NEXT', 1, 'Show next \d+ jobs' ] , # meaning how to find the NEXT button.
            [ 'COUNT', 'Jobs [-0123456789]+ of (\d+) matching your query' ] , # the total count can be found here.
            [ 'HIT*' ,                          # meaning the content of this array element represents hits!
               [  
                  [ 'DL',                       # meaning detail is in a definition list
                     [
                        [ 'DT', [[ 'F', \&titleJobID, 'url', 'title', 'jobID' ]] ] # meaning that the job description link is here, in the definition term, 
                       ,[ 'DD', [[ 'F', \&touchupLocation, 'location', 'description']] ] # meaning the location is in the definition data.
                       ,[ 'RESIDUE', 'residue' ]
                     ]
                  ]
               ]
            ]
         ] 
      ];


sub init {
    my ($self) = @_;
    $self->searchEngineHome('http://www.Dice.com');
}

sub testParameters {
    my ($self) = @_;
    
    if ( ref $self ) {
        $self->{'isTesting'} = 1;
    }
    
    # 'POST' style scraperFrames can't be tested cause of a bug in WWW::Search(2.2[56]) !
    return {
                 'SKIP' => ''
                ,'TODO' => "Dice is dicey; one moment it works, the next moment it doesn\'t (it mostly works, though)" #\nUses POST: certain versions of WWW::Search (2.25, aka 2.27, to name one) fail with POSTs."
                ,'testNativeQuery' => 'Perl NOT Java'
                ,'expectedOnePage' => 9
                ,'expectedMultiPage' => 21
                ,'expectedBogusPage' => 0
                ,'usesPOST' => 1
           };
}

# Access methods for the structural declarations of this Scraper engine.
sub scraperRequest { $scraperRequest }
sub scraperFrame { $scraperFrame }
sub scraperDetail{ undef }

# private
sub native_retrieve_someX
  {
  my ($self) = @_;
  my $debug = $self->{'_debug'};
  print STDERR " *   Dice::native_retrieve_some()\n" if ($debug);
  
  # fast exit if already done
  return undef if (!defined($self->{_next_url}));

  my $dicesBogusErrorMessage = 'Please wait a moment and click \<b\>Reload\<\/b\> to retry your search';
  my $bogus;
  my ($response,$tag,$url);
    my $still_getting_bogus_response = 0;
	do
	{
		# Dice always redirects the first query to the first result page (via HTTP code 302)
        if ($self->{_first_call})
		{
			print STDERR "Sending POST request to " . $self->{_next_url} .
			"\tPOST options: " . $self->{_to_post} . "\n" 
			if ($debug);
			my $req = new HTTP::Request('POST', $self->{_next_url});
			$req->content_type('application/x-www-form-urlencoded');
			$req->content($self->{_to_post});
			my $ua = $self->{user_agent};
			$response = $ua->request($req);
			$self->{'_response'} = $response;
			if ( $response->content() =~ m/$dicesBogusErrorMessage/ )
			{
				$still_getting_bogus_response += 1;
				if ( $still_getting_bogus_response < 20 )
				{
					print STDERR "Got '$dicesBogusErrorMessage'; will reload in three seconds.\n" if ($debug);
					sleep 3;
					next;
				} else
				{
					print STDERR "Recieved '$dicesBogusErrorMessage' $bogus times. Can't get response from Dice.com\n" if $debug; 
					$self->{'_next_url'} = undef;
					return undef;
				}
			}
			$still_getting_bogus_response = 0;
            $self->{_first_call} = 0;

			if ($response->content() =~ 
				m/Sorry, no documents matched your search criteria/)
			{
				print STDERR "Sorry, no hits found\n" if $debug; 
				$self->{'_next_url'} = undef;
				return undef;
			}

			my $p = new HTML::TokeParser(\$response->content());
			$tag = $p->get_tag("a");
			$url = $tag->[1]{href};
			$url =~ s/\;/\&/g;
			$self->{'_next_url'} = $url;
			print STDERR "Next url is " . $self->{'_next_url'} . "\n" if ($debug);
		}

        print STDERR " *   sending request (",$self->{_next_url},")\n" if ($debug);
        $response = $self->http_request('GET', $self->{_next_url});  
        $self->{'_response'} = $response;
        if ( $response->content() =~ m/$dicesBogusErrorMessage/ )
        {
            $still_getting_bogus_response += 1;
            if ( $still_getting_bogus_response < 20 )
            {
                print STDERR "Got '$dicesBogusErrorMessage'; will reload in three seconds.\n" if ($debug);
                sleep 3;
                next;
            } else
            {
                print STDERR "Received '$dicesBogusErrorMessage' $bogus times. Can't get response from Dice.com\n" if $debug; 
                $self->{'_next_url'} = undef;
                return undef;
            }
        }
        $still_getting_bogus_response = 0;

        print STDERR " *   got response\n" if ($debug);
        $self->{'_next_url'} = undef;
        if (!$response->is_success)
        {
            print STDERR $response->error_as_HTML;
            return undef;
        }
	} while ( $still_getting_bogus_response );
  
      my $hits_found = $self->scrape($response->content(), $self->{_debug});

      # sleep so as to not overload Dice
      $self->user_agent_delay if (defined($self->{_next_url}));

      return $hits_found;
} # native_retrieve_some


sub titleJobID {
    my ($self, $hit, $dat) = @_;
   my ($url) = ($dat =~ m{<a.*?href="([^"]*)"});
    $dat = $self->trimTags($hit, $dat);
    if ( $dat =~ /^(.*?)\s+-\s+(.*)$/s ) {
        return ($url,$2,$1);
    } else {
        return ($dat,$dat, '');
    }
}


# The location data of Dice's brief page contains both
#  Location and Description, so we need to split them here.
# e.g. "CA-408-San Jose-ASIC Verification,SONET,ATM,C++,UNIX,Perl."
sub touchupLocation {
   my ($self, $hit, $dat) = @_;
   
   $dat = WWW::Search::Scraper::trimTags($self, $hit, $dat);
   if ( $dat =~ m/(.+-\d+.+)-(.*)/si )
   {
      return ($1, $2);
   } else
   {
      return ($dat, "WWW::Search::Dice.pm can't find location-description in '$dat'");
   }
}


{
package WWW::Search::Scraper::Response::Job::Dice;

use WWW::Search::Scraper::Response::Job;
use vars qw(@ISA);
@ISA = qw(WWW::Search::Scraper::Response::Job);

sub resultTitles {
    my $self = shift;
    my $resultT = $self->SUPER::resultTitles();
    $$resultT{'jobID'} = 'Job ID';
    return $resultT;
}

sub results {
    my $self = shift;
    my $results = $self->SUPER::results();
    return undef unless $results;
    $$results{'jobID'} = $self->jobID();
    return $results;
}

sub jobID { return $_[0]->_elem('jobID'); }


}


1;

__END__

=pod

=head1 NAME

WWW::Search::Scraper::Dice - Scrapes Dice : (skills,locations) => (title, location ,residue)

=head1 SYNOPSIS

 use WWW::Search;
 my $oSearch = new WWW::Search::Scraper('Dice');
 my $sQuery = WWW::Search::Scraper::escape_query("unix and (c++ or java)");
 $oSearch->native_query($sQuery,
 			{'method' => 'bool',
		         'state' => 'CA',
		         'daysback' => 14});
 while (my $res = $oSearch->next_result()) {
     if(isHitGood($res->url)) {
 	 my ($company,$title,$date,$location) = 
	     ($res->company, $res->title, $res->date, $res->location);
 	 print "$company $title $date $location " . $res->url . "\n";
     } 
 }

=head1 DESCRIPTION

This class is a Dice extension of WWW::Search::Scraper.
It handles making and interpreting Dice searches at
F<http://www.dice.com>.

=head1 OPTIONS 

The following search options can be activated by sending
a hash as the second argument to native_query().

=head2 Format / Treatment of Query Terms

The default is to treat entire query as a boolean
expression with AND, OR, NOT and parentheses

=over 2

=item   {'method' => 'and'}

Logical AND of all the query terms.

=item   {'method' => 'or'}

Logical OR of all the query terms.

=item   {'method' => 'bool'}

treat entire query as a boolean expression with 
AND, OR, NOT and parentheses.
This is the default option.

=back

=head2 Restrict by Date

The default is to return jobs posted in last 30 days

=over 2

=item   {'daysback' => $number}

Display jobs posted in last $number days

=back

=head2 Restrict by Location

The default is "ALL" which means all US states

=over 2

=item   {'state' => $state} - Only jobs in state $state.

=item   {'state' => 'CDA'} - Only jobs in Canada.

=item   {'state' => 'INT'} - To select international jobs.

=item   {'state' => 'TRV'} - Require travel.

=item   {'state' => 'TEL'} - Display telecommute jobs.

=back

Multiple selections are possible. To do so, add a "+" sign between
desired states, e.g. {'state' => 'NY+NJ+CT'}

You can also restrict by 3-digit area codes. The following option does that:

=over 2

=item   {'acode' => $area_code}

=back

Multiple area codes (up to 5) are supported.

=head2 Restrict by Job Term

No restrictions by default.

=over 2

=item {'taxterm' => 'CON_W2' - Contract - W2

=item {'taxterm' => 'CON_IND' - Contract - Independent

=item {'taxterm' => 'CON_CORP' - Contract - Corp-to-Corp

=item {'taxterm' => 'CON_HIRE_W2' - Contract to Hire - W2

=item {'taxterm' => 'CON_HIRE_IND' - Contract to Hire - Independent

=item {'taxterm' => 'CON_HIRE_CORP' - Contract to Hire - Corp-to-Corp

=item {'taxterm' => 'FULLTIME'} - full time

								<option value="" selected>No Restrictions</option>
								<option value="CON_W2">Contract - W2</option>
								<option value="CON_IND">Contract - Independent</option>
								<option value="CON_CORP">Contract - Corp-to-Corp</option>
								<option value="CON_HIRE_W2">Contract to Hire - W2</option>
						<option value="CON_HIRE_IND">Contract to Hire - Independent</option>
					<option value="CON_HIRE_CORP">Contract to Hire - Corp-to-Corp</option>
								<option value="FULLTIME">Full - time</option>
=back

Use a '+' sign for multiple selection.

There is also a switch to select either W2 or Independent:

=over 2

=item {'addterm' => 'W2ONLY'} - W2 only

=item {'addterm' => 'INDOK'} - Independent ok

=back

=head2 Restrict by Job Type

No restriction by default. To select jobs with specific job type use the
following option:

=over 2

=item   {'jtype' => $jobtype}

=back

Here $jobtype (according to F<http://www.dice.com>) can be one or more 
of the following:

=over 2

=item * ANL - Business Analyst/Modeler

=item * COM - Communications Specialist

=item * DBA - Data Base Administrator

=item * ENG - Other types of Engineers

=item * FIN - Finance / Accounting

=item * GRA - Graphics/CAD/CAM

=item * HWE - Hardware Engineer

=item * INS - Instructor/Trainer

=item * LAN - LAN/Network Administrator

=item * MGR - Manager/Project leader

=item * OPR - Data Processing Operator

=item * PA - Application Programmer/Analyst

=item * QA - Quality Assurance/Tester

=item * REC - Recruiter

=item * SLS - Sales/Marketing

=item * SWE - Software Engineer

=item * SYA - Systems Administrator

=item * SYS - Systems Programmer/Support

=item * TEC - Custom/Tech Support

=item * TWR - Technical Writer

=item * WEB - Web Developer / Webmaster

=back

=head2 Limit total number of hits

The default is to stop searching after 500 hits.

=over 2

=item  {'num_to_retrieve' => $num_to_retrieve}

Changes the default to $num_to_retrieve.

=back

=head1 AUTHOR

Copyright (c) 2001 Glenn Wood http://search.cpan.org/search?mode=author&query=GLENNWOOD

All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 LEGALESE

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

