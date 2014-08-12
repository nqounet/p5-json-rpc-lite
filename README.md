# NAME

JSON::RPC::Lite - Simple Syntax JSON RPC 2.0 Server Implementation

# SYNOPSIS

    # app.psgi
    use JSON::RPC::Lite;
    method 'echo' => sub {
        return $_[0];
    };
    as_psgi_app;

# DESCRIPTION

JSON::RPC::Lite is sinatra-ish style JSON RPC 2.0 Server Implementation.

# LICENSE

Copyright (C) nqounet.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

nqounet <mail@nqou.net>
