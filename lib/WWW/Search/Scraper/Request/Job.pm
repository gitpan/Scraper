package WWW::Search::Scraper::Request::Job;

use strict;

use vars qw($VERSION @ISA);
@ISA = qw( WWW::Search::Scraper::Request );
use WWW::Search::Scraper::Request;

sub skills    { shift->field('skills', @_); }
sub locations { shift->field('locations', @_); }
sub payrate   { shift->field('payrate', @_); }


### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 
# For Scraper modules to lazy to do their own postSelect(), we can do a Request::Job version of it.
sub postSelect {
    my ($rqst, $scraper, $rslt, $alreadyDone) = @_;
    
return 1; # WE'LL WORK OVER THIS LATER. gdw.2001.07.14
# With all that's happening in Scraper.pm and FieldTranslation.pm, I wonder if there will be a later? gdw.2001.07.05
    
    # postSelect by locations - make sure the city and state appear in the $rslt->locations.
    # ? ? ? 

    # Default is true, unless one of the previous check intercept it!
    return 1;
}


1;

__END__

=head1 NAME

WWW::Search::Scraper::Request::Job - Canonical form for Scraper::Job requests

=head1 SYNOPSIS

    use WWW::Search::Scraper::Request::Job;

    $rqst = new WWW::Search::Scraper::Request::Job;
    $rqst->skills(['Perl', '!Java']);
    $rqst->locations('CA-San Jose');
    $rqst->payrate('100000/A');

=head1 DESCRIPTION

This module provides a canonical taxonomy for specifying requests to search engines (via Scraper modules).
C<Request::Job> is targeted toward job searches.

See the C<WWW::Search::Scraper::Request> module for a description of how this interfaces with Scraper modules.

=head1 FIELDS

=head2 skills

The C<skills> field should be a string, or a reference to an array of strings,
specifying the skills associated with the target job. The semantics here is that
these will be AND-ed by the search engine (i.e., the jobs found will match all the skills).

Use a '+' symbol inside the string to specify "skill A OR skill B".

Use a '!' operator at the beginning of the string to specify that that skill should NOT appear in the job title.
(This is the only place '!' is recognized in this way.)

=head2 locations

The C<locations> field should be a string, or a reference to an array of strings,
specifying the acceptable geographic locations for the job results. The string(s)
should be in the form "SS-Ccccccc", where "SS" is the two letter state name, and 
"Cccccc" is the city name (properly capitalized).

It is the responsibility of the Scraper module to translate these strings into the
appropriate location codes used by their search engines. This may mean an extremely
large lookup table, but there you are! It is also probable that the Scraper module
must postSelect based on this field, since there's seldom a one-to-one match between
our canonical location and a target search engine's location taxonomy.

We've provided an example of how this is done in Brainpower.pm.

(International locations must be handled specially, per Scraper module).

=head2 payrate

This is the desired hourly rate, in dollars (optionally append with '/H').
To specify an annual salary, append the rate with the characters '/A'.
To specify a monthly salary, append the rate with the characters '/M'.
To specify a weekly salary, append the rate with the characters '/W'.

=head1 AUTHOR

C<WWW::Search::Scraper::Request> is written and maintained
by Glenn Wood, <glenwood@alumni.caltech.edu>.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut



