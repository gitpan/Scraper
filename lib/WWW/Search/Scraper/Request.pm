
package WWW::Search::Scraper::Request;

sub new {
    my ($self, $native_query, $native_options_ref) = @_;
    $self = bless {}, $self;
    
    $self->{'query'} = $native_query; # This should be translated from generic query to native query.
    if (defined($native_options_ref)) {
    	# Copy in new options.
    	foreach (keys %$native_options_ref) {
    	    $self->{'queryOptions'}{$_} = $native_options_ref->{$_} if defined $native_options_ref->{$_};
    	};
    };
    return $self;
}

sub generateQuery {
    my ($self, $query) = @_;

    # Process the inputs.
    # (Now in sorted order for consistency regardless of hash ordering.)
    my $options = $self->{'queryFieldName'}.'='.WWW::Search::escape_query($query);
    my $options_ref = $self->{'queryOptions'};
    foreach (sort keys %$options_ref) {
        $options .= "&$_=".WWW::Search::escape_query($options_ref->{$_});
    };
    
    return $self->{'_base_url'}.$options;

}
1;

