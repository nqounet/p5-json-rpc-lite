requires 'perl', '5.008001';
requires 'Router::Simple', 0;
requires 'JSON::RPC::Dispatch', 0;

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Plack::Test', 0;
};

