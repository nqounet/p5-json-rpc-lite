use strict;
use Test::More 0.98;
use Plack::Test;
use HTTP::Request::Common;

use JSON::RPC::Lite;

use DDP {deparse => 1};

eval <<EOM;
method 'echo' => sub {
    return $_[0];
};
as_psgi_app;
EOM

ok !$@, 'sinatra-ish syntax.';

my $method = method('echo2', sub { $_[0] });
is ref $method, 'JSON::RPC::Spec', 'instance of `JSON::RPC::Spec`';

my $psgi_app = as_psgi_app;
is ref $psgi_app, 'CODE', 'CODE refs';

my $test = Plack::Test->create($psgi_app);
ok ref $test, 'create app';

my $res = $test->request(
    POST '/',
    'Content-Type' => 'application/json',
    Content        => '{"jsonrpc":"2.0","method":"echo":"params":"","id":1}'
);
p $res;
ok $res, 'request';

done_testing;
