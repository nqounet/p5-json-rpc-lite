package JSON::RPC::Lite;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use Router::Simple;
use JSON::RPC::Dispatch::Lite;

sub import {
    my $pkg    = caller(0);
    my $router = Router::Simple->new;
    my $method = sub ($$) {
        my ($pattern, $code) = @_;
        $router->connect($pattern, +{code => $code}, +{});
    };
    no strict 'refs';
    *{"${pkg}::method"}      = $method;
    *{"${pkg}::as_psgi_app"} = sub {
        my $dispatch = JSON::RPC::Dispatch::Lite->new(router => $router);
        return sub {
            $dispatch->handle_psgi($_[0]);
        };
    };
}

1;
__END__

=encoding utf-8

=head1 NAME

JSON::RPC::Lite - Simple Syntax JSON RPC 2.0 Server Implementation

=head1 SYNOPSIS

    # app.psgi
    use JSON::RPC::Lite;
    method 'echo' => sub {
        my ($param) = @_;
        return $param;
    };
    as_psgi_app;

=head1 DESCRIPTION

JSON::RPC::Lite is lite version of JSON::RPC.

=head1 LICENSE

Copyright (C) nqounet.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

nqounet E<lt>nobu@nishimiyahara.netE<gt>

=cut

