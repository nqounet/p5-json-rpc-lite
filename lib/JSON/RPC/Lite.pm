package JSON::RPC::Lite;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use JSON::RPC::Spec;
use Plack::Request;

sub import {
    my $pkg    = caller(0);
    my $rpc    = JSON::RPC::Spec->new;
    my $method = sub ($$) {
        my ($pattern, $code) = @_;
        $rpc->register($pattern, $code);
    };
    no strict 'refs';
    *{"${pkg}::method"}      = $method;
    *{"${pkg}::as_psgi_app"} = sub {
        return sub {
            my $req    = Plack::Request->new(@_);
            my $body   = $rpc->parse($req->content);
            my $header = ['Content-Type' => 'application/json'];
            if (length $body == 0) {
                return [204, [], []];
            }
            my $status = 200;
            if (exists $body->{error}) {
                my $code = $body->{error}{code};
                if ($code == -32600) {
                    $status = 400;
                }
                elsif ($code == -32601) {
                    $status = 404;
                }
                else {
                    $status = 500;
                }
            }
            return [$status, $header, [$body]];
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
        return $_[0];
    };
    as_psgi_app;

=head1 DESCRIPTION

JSON::RPC::Lite is sinatra-ish style JSON RPC 2.0 Server Implementation.

=head1 LICENSE

Copyright (C) nqounet.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

nqounet E<lt>mail@nqou.netE<gt>

=cut
