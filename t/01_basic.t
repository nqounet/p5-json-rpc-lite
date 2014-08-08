use strict;
use Test::More 0.98;
use Plack::Test;

use JSON::RPC::Lite;

use DDP {deparse => 1};

eval <<EOM;
method 'echo' => sub {
    return $_[0];
};
as_psgi_app;
EOM

ok !$@, 'sinatra-ish syntax.';

my $method = method('echo2', sub {$_[0]});

is ref $method, 'Router::Simple', 'instance of Router::Simple.';

my $matched = $method->match('echo2');

ok $matched, 'matched `echo2`.';

my $psgi_app = as_psgi_app;

is ref $psgi_app, 'CODE', 'CODE refs';

my $app = Plack::Test->create($psgi_app);

ok ref $app, 'create app';

done_testing;
