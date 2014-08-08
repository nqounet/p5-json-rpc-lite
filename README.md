# NAME

JSON::RPC::Lite - Simple Syntax JSON RPC 2.0 Server Implementation

# SYNOPSIS

    # app.psgi
    use JSON::RPC::Lite;
    method 'echo' => sub {
        my ($param) = @_;
        return $param;
    };
    as_psgi_app;

# DESCRIPTION

JSON::RPC::Lite is lite version of JSON::RPC.

# LICENSE

Copyright (C) nqounet.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

nqounet <nobu@nishimiyahara.net>
