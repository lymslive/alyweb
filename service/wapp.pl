#! /usr/bin/env perl
# websocket 简易框架
package wapp;
use strict;
use warnings;

# 三方模块
use Net::WebSocket::Server;
use Getopt::Long;
use JSON;
use Log::Log4perl qw(get_logger);

# 默认参数常量
use constant PORT => 8081;
use constant DEBUG => 1;
use constant TICK => 5;
use constant LOG_CONF => 'log.conf';

# 处理命令行参数
my $port = PORT;
my $debug = DEBUG;
my $tick = TICK,
my $log_conf = LOG_CONF;

GetOptions (
	"port=i" => \$port,
	"debug=i"   => \$debug,
	"tick=i"   => \$tick,
	"log=s"   => \$log_conf,
) or die("Error in command line arguments\n");

# 日志系统
Log::Log4perl->init_and_watch($log_conf, 'HUP');
my $logger = get_logger();

# 处理文本消息
sub handle_message
{
	my ($conn, $msg) = @_;
	$logger->info("recd: $msg");
	$conn->send_utf8($msg);
	$logger->info("send: $msg");
}

# 处理二进制消息
sub handle_binary
{
	my ($conn, $msg) = @_;
	# todo
}

# 处理定时事件
sub handle_tick
{
	my ($serv) = @_;
	$logger->info("tick event on sever!");
	# todo
}

# 处理握手事件
sub handle_handshake
{
	my ($conn, $handshake) = @_;
	# todo
}

# 处理连接，为连接对象设置回调事件
sub handle_connect
{
	my ($serv, $conn) = @_;
	$logger->info("connected!");
	$conn->on(
		utf8 => \&handle_message,
		binary => \&handle_binary,
		handshake => \&handle_handshake,
	);
}

# 启动 websocket 服务
warn "to start websocket service ...\n";
$logger->info("to start websocket service ...");
Net::WebSocket::Server->new(
	listen => $port,
	on_connect => \&handle_connect,
	tick_period => $tick,
	on_tick => \&handle_tick,
)->start;
$logger->info("to finish websocket service ...");
warn "to finish websocket service ...\n";
