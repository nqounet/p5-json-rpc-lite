package JSON::RPC::Dispatch::Lite;
use strict;
use warnings;
use parent 'JSON::RPC::Dispatch';
use JSON::RPC::Constants qw(:all);
use Try::Tiny;

sub handle_psgi {
    my ($self, $req, @args) = @_;

    if ( ! Scalar::Util::blessed($req) ) {
        # assume it's a PSGI hash
        require Plack::Request;
        $req = Plack::Request->new($req);
    }

    my @response;
    my $procedures;
    try {
        $procedures = $self->parser->construct_from_req( $req );
        if (@$procedures <= 0) {
            push @response, {
                error => {
                    code => RPC_INVALID_REQUEST,
                    message => "Could not find any procedures"
                }
            };
        }
    } catch {
        my $e = $_;
        if (JSONRPC_DEBUG) {
            warn "error while creating jsonrpc request: $e";
        }
        if ($e =~ /Invalid parameter/) {
            push @response, {
                error => {
                    code => RPC_INVALID_PARAMS,
                    message => "Invalid parameters",
                }
            };
        } elsif ( $e =~ /parse error/ ) {
            push @response, {
                error => {
                    code => RPC_PARSE_ERROR,
                    message => "Failed to parse json",
                }
            };
        } else {
            push @response, {
                error => {
                    code => RPC_INVALID_REQUEST,
                    message => $e
                }
            }
        }
    };

    my $router = $self->router;
    foreach my $procedure (@$procedures) {
        if ( ! $procedure->{method} ) {
            my $message = "Procedure name not given";
            if (JSONRPC_DEBUG) {
                warn $message;
            }
            push @response, {
                error => {
                    code => RPC_METHOD_NOT_FOUND,
                    message => $message,
                }
            };
            next;
        }

        my $is_notification = defined $procedure->jsonrpc && $procedure->jsonrpc eq '2.0' && !$procedure->has_id;
        my $matched = $router->match( $procedure->{method} );
        if (! $matched) {
            my $message = "Procedure '$procedure->{method}' not found";
            if (JSONRPC_DEBUG) {
                warn $message;
            }
            if (!$is_notification) { # must not respond to a valid JSON-RPC notification
                push @response, {
                    error => {
                        code => RPC_METHOD_NOT_FOUND,
                        message => $message,
                    }
                };
            }
            next;
        }

        my $action = $matched->{action};
        try {
            my $result;
            my $code = $matched->{code};
            if (!$code) {
                my ($ip, $ua);
                if (JSONRPC_DEBUG > 1) {
                    warn "Procedure '$procedure->{method}' maps to action $action";
                    $ip = $req->address || 'N/A';
                    $ua = $req->user_agent || 'N/A';
                }
                my $params = $procedure->params;
                my $handler = $self->get_handler( $matched->{handler} );

                $code = $handler->can( $action );
                if (! $code) {
                    if ( JSONRPC_DEBUG ) {
                        warn "[INFO] handler $handler does not implement method $action!.";
                    }
                    die "Internal Error";
                }
                $result = $code->( $handler, $procedure->params, $procedure, @args );
                if (JSONRPC_DEBUG) {
                    warn "[INFO] action=$action "
                        . "params=["
                        . (ref $params ? $self->{coder}->encode($params) : $params)
                        . "] ret="
                        . (ref $result ? $self->{coder}->encode($result) : $result)
                        . " IP=$ip UA=$ua";
                }
            }
            else {
                $result = $code->( $procedure->params, $procedure, @args );
            }

            # respond unless we are sure a procedure is a notification
            if (!$is_notification) {
                push @response, {
                    jsonrpc => '2.0',
                    result  => $result,
                    id      => $procedure->id,
                };
            }
        } catch {
            my $e = $_;
            if (JSONRPC_DEBUG) {
                warn "Error while executing $action: $e";
            }
            # can't respond to notifications even in case of errors
            if (!$is_notification) {
                my $error = {code => RPC_INTERNAL_ERROR} ;
                if (ref $e eq "HASH") {
                   $error->{message} = $e->{message},
                   $error->{data}    = $e->{data},
                } else {
                   $error->{message} = $e,
                }
                push @response, {
                    jsonrpc => '2.0',
                    id      => $procedure->id,
                    error   => $error,
                };
            }
        };
    }

    my $res;
    if (scalar @response) {
        $res = $req->new_response(200);
        $res->content_type( 'application/json; charset=utf8' );
        $res->body(
            $self->coder->encode( @$procedures > 1 ? \@response : $response[0] )
        );
        return $res->finalize;
    } else { # no content
        $res = $req->new_response(204);
    }

    return $res->finalize;
}

1;

=encoding utf-8

=head1 NAME

JSON::RPC::Dispatch::Lite - JSON::RPC::Dispatch small patched for JSON::RPC::Lite

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

