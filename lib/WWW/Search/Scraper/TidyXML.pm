
# Download source from http://tidy.sourceforge.net/docs/Overview.html#Download
# http://tidy.sourceforge.net/
### XML TOOLS !
# http://www.garshol.priv.no/download/xmltools/cat_ix.html#SC_GNConv

# http://www.chami.com/html-kit/
# --output-xml yes --output-xhtml yes --add-xml-decl yes



package WWW::Search::Scraper::TidyXML;
$VERSION = sprintf("%d.%02d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/);

use strict;

{ package WWW::Search::Scraper::TidyXML::_struct_;
use Class::Struct;
    struct ( 
                 'm_asXML'   => '$'
                ,'m_asString'  => '$'
                ,'m_xmlParser' => '$'
                ,'m_TRACE' => '$'
                ,'m_implicitRootNode' => '$'
           );
}
use base qw(WWW::Search::Scraper::TidyXML::_struct_);

sub new {
    my $self = new WWW::Search::Scraper::TidyXML::_struct_;
    bless $self, shift;
    my $string = shift;
    
    if ( $string and not ref $string ) {
        open TMP, "<$string" or die "Can't open '$string': $!\n";
        my @tmp = <TMP>;
        close TMP;
        my $tmp = join '',@tmp;
        $string = \$tmp;
    }

    if ( $string and not ($$string =~ m-<meta name="generator" content="HTML Tidy, see www.w3.org" />-s) ) {
        open TMP, ">temp" or die "Can't open 'temp': $!";
        print TMP $$string;
        close TMP;
        my $rslt = `tidy -upper -asxml -numeric temp 2>temp.err`;
#        unlink 'temp';
        die "This Scraper engine requires 'Tidy' to scrub HTML before parsing.\nGet this program from 'http://tidy.sourceforge.net/docs/Overview.html#Download'\n" unless $rslt;

        $string = \$rslt;
    }
    $self->m_asString($string);
    return $self;
}

sub TRACE {
    return ( $_[0]->m_TRACE() =~ m-$_[1]- );
}


# Extract the given xml path from the given TidyXML. Return reference to the string version.
sub asString {
    my ($self, $xmlPath) = @_;

    unless ( defined $xmlPath ) {
        my $result = $self->m_asString();
        unless ( $result ) {
            my $parsedXML = $self->m_asXML();
            my $xml;
            $xml = $parsedXML->toString() if $parsedXML;
            $result = \$xml;
            $self->m_asString($result);
        }
        return $result;
    }
    
    print STDERR "TidyXML::asString($xmlPath)\n" if $self->TRACE('T');

    my $xml = $self->m_asString();
    my $parsedXML = $self->m_asXML();
    my @xmlPath = split /\./, $xmlPath;
    unshift @xmlPath, $self->m_implicitRootNode if $self->m_implicitRootNode;

    for my $tag ( @xmlPath ) {
    
        my $newXml;
        my $count = 1;
        if ( $tag =~ s-\((\d+)\)$-- ) {
            $count = $1;
        }
       
       print STDERR "Capturing '$tag' " if $self->TRACE('T');
       if ( $tag =~ s-^\*-- ) {
           ####
           #### Text-wise parsing . . .
           ####
           die "Text-wise parsing is not yet implemented in ".ref($self)."\n";
          print STDERR "Text-wise\n" if $self->TRACE('T');
          $xml = $self->m_asXML()->toString() if ( $self->m_asXML() and not $self->asString() ); # The parsedXML mode signals non-parsedXMLmode with this condition.
          for ( 1..$count ) {
             unless ( $newXml = $self->getMarkedText($tag, $xml) ) { die "Can't find '$tag($_)'\n"; }
          }
          $xml = "<$tag>$newXml</$tag>";
          $self->m_asString(\$xml);
          $self->m_asXML('');
       } else {

           ####
           #### XML::DOM-wise parsing . . .
           ####
          print STDERR "XML::DOM-wise\n" if $self->TRACE('T');
          unless ( $self->m_xmlParser() ) {
              # Just-in-time instantiation of XML::DOM::parser.
             eval { use XML::DOM;
                     $self->m_xmlParser( new XML::DOM::Parser );
                  };
             die "Can't create XML::DOM parser: $!" if $@;
          }
# <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
          unless ( $parsedXML ) {
             # Just-in-time parsing of the TidyXML string.
             return \undef unless $$xml;
             eval { $parsedXML = $self->m_xmlParser()->parse($$xml) };
             if ( $@ =~ m/duplicate attribute/ ) {
                 # Then this one even Tidy can't tidy-up!
                 $self->removeDuplicateAttributes($xml);
                 eval { $parsedXML = $self->m_xmlParser()->parse($$xml) };
             }
             die "Can't XML parse : $! $@" if $@;
             $self->m_asXML($parsedXML);
             $xml = undef;
          }
          if ( $xml ) {
              eval { $parsedXML = $self->m_xmlParser()->parse($$xml) };
              die "Can't XML parse: $!, $@" if $@;
              $xml = undef;
          }
          if ( $parsedXML ) {
              my $elements = $parsedXML->getElementsByTagName($tag, 0);
              return \undef unless $parsedXML = $elements->item($count-1);
          }
       }
    }

    # Remove the found region from the TidyXML.
    if ( $parsedXML ) {
        $parsedXML->getParentNode()->removeChild($parsedXML);
    }

#    $xml = $self->m_asString($self->m_asXML()->toString()) if ( $self->m_asXML() and not $xml ); # The parsedXML mode signals non-parsedXMLmode with this condition.
    
    if ( $parsedXML ) {
        $self->m_asString(undef);
        my $result = $parsedXML->toString();
        return \$result;
    } else {
        die "Text-wise parsing and control is not yet implemented in ".ref($self)."\n";
        $self->m_asString($xml);
        return $self->m_asString();
    }
}

# Extract the given xml path from the given TidyXML. Return the xml version.
sub asXML { 
    my ($self, $xmlPath) = @_;

    return $self->m_asXML() unless defined $xmlPath;
    
    die "TidyXML::asXML(path) is not implemented.";
}



sub removeDuplicateAttributes {
    my ($self, $xml) = @_;

    $$xml =~ s-alt=""--gs; # this one appears from Dogpile.com

}
# Returns the marked up text from the referenced string, as designated by the given tag.
# This algorithm extracts the contents of the first <$tag> element it encounters,
#   taking into consideration that it may contain <$tag> elements within it.
# It removes the marked text from the original string, strips off the markup tags,
#   and returns that result.
# (if wantarray, will return result and first tag, with brackets removed)
#
sub getMarkedText {
    my ($tag, $content) = @_;
    
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

sub isNotTestable {
    my $rslt = `tidy -version 2>tidy.stderr`;
    if ( $? ) {
        return "This Scraper engine requires 'HTML Tidy' to scrub HTML before parsing.\nGet this program from 'http://tidy.sourceforge.net/docs/Overview.html#Download'\nMake sure it is in your execution search path.\n";
    }
    return '';
}


1;



__END__
=pod

=head1 NAME

WWW::Search::Scraper::TidyXML - base class for structuring and scraping ill-formed HTML

=head1 SYNOPSIS

    Use WWW::Search::Scraper::TidyXML 

in your Scraper module.

Use 'TidyXML' and 'XML' options in the scraperFrame to locate relevant regions of the results and details pages.

=head1 DESCRIPTION

One of the easiest ways to implement a Scraper engine for a new search engine is to use the "TidyXML" method.

The basic idea behind TidyXML is to convert the search engine's results page into XML.
Then it is *much* easier to locate regions in the results page that contain the relevant data.

Here is how it works:

1. Process the results page through the Tidy program (available at tidy.sourceforge.com).

2. Convert the search engine's results page to XML with Tidy (via 'TidyXML' option in the scraperFrame).

3. Select relevant data via the 'XML' scraperFrame operation.

Most search engines generate remarkably ill-structured HTML. The Tidy program fixes that up,
converts it to well-formed XML, making it accessible to Scraper's XML parsing operations.
As XML, it is much easier to identify the relevant regions.

To initially develop a TidyXML-based Scraper module, you, as an implementor,
manually process a results page through Tidy (using the -asxml option).
This produces an XML file that can be viewed with any XML viewer. 
Internet Explorer or Netscape Navigator work well for this
(my personal favorite is XMLSpy. Try toolbar 'Table'.'Display as Table' option for revealing views
 - get a 30-day free trial at www.xmlspy.com).

Browse the XML to visually identify the relevant regions.
Then code these regions into your new engine implementation via a dot-notation.
E.G., the first <TABLE> of the converted HTML would be coded

	html.body.table

Skipping the first <TABLE> to select the second table would be coded

	html.body.table(2)

You would then pass this <TABLE> to your next phase, where <TR>s in that table would be coded

	tr

and <TD>'s within that <TR> might be coded

	tr.td(1)
	tr.td(2)
	etc.

Complete the coding of your new engine implementation by specifying TidyXML conversion in the ScraperFrame.
This causes Scraper repeat these Tidy conversions on each results page it processes.

=head1 EXAMPLES

Here is an example scraperFrame from a simple implimentation for Dogpile.com

       [ 'TidyXML',
           [ 
              [ 'XML', 'html.body',
                 [
                    [ 'HIT*' ,
                       [
                          [ 'XML', 'p',
                             [
                                [ 'A', 'url', 'title' ]
                               ,[ 'XML', 'i', 'company' ]
                             ]
                          ],
                       ]
                    ]
                 ]
              ]
           ]
       ]

This took me a leisurely 30 minutes to discover and implement.
Of course, Dogpile is remarkably well formed to begin with, 
and even there a complete implementation does require a few more touches. 
Take a look at Dogpile.pm for further details.

=head1 AUTHOR and CURRENT VERSION

C<WWW::Search::Scraper::TidyXML> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2002 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut



