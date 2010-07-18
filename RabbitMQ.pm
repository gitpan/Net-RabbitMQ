package Net::RabbitMQ;

require DynaLoader;

use strict;
use vars qw($VERSION @ISA);
$VERSION = "0.1.6";
@ISA = qw/DynaLoader/;

bootstrap Net::RabbitMQ $VERSION ;

=head1 NAME

Net::RabbitMQ - interact with RabbitMQ over AMQP using librabbitmq

=head1 SYNOPSIS

	use Net::RabbitMQ;
	my $mq = Net::RabbitMQ->new();
	$mq->connect("localhost", { user => "guest", password => "guest" });
	$mq->channel_open(1);
	$mq->publish(1, "queuename", "Hi there!");
	$mq->disconnect();
	
=head1 DESCRIPTION

C<Net::RabbitMQ> provides a simple wrapper around the librabbitmq library
that allows connecting, delcaring exchanges and queues, binding and unbinding
queues, publising, consuming and receiving events.

Error handling in this module is primarily achieve by Perl_croak (die). You
should be making good use of eval around these methods to ensure that you
appropriately catch the errors.

=head2 Methods

All methods, unless specifically stated, return nothing on success
and die on failure.

=over 4

=item new()

Creates a new Net::RabbitMQ object.

=item connect( $hostname, $options )

C<$hostname> is the host to which a connection will be attempted.

C<$options> is an optional hash respecting the following keys:

     {
       user => $user,           #default 'guest'
       password => $password,   #default 'guest'
       port => $port,           #default 5672
       vhost => $vhost,         #default '/'
       channel_max => $cmax,    #default 0
       frame_max => $fmax,      #default 131072
       heartbeat => $hearbeat,  #default 0
     }

=item disconnect()

Causes the connection to RabbitMQ to be torn down.

=item channel_open($channel)

C<$channel> is a positive integer describing the channel you which to open.

=item channel_close($channel)

C<$channel> is a positive integer describing the channel you which to close.

=item get_channel_max()

Returns the maximum allowed channel number.

=item exchange_declare($channel, $exchange, $options)

C<$channel> is a channel that has been opened with C<channel_open>.

C<$exchange> is the name of the exchange to be instantiated.

C<$options> is an optional hash respecting the following keys:

     {
       exchange_type => $type,  #default 'direct'
       passive => $boolean,     #default 0
       durable => $boolean,     #default 0
       auto_delete => $boolean, #default 1
     }

=item exchange_delete($channel, $exchange, $options)

C<$channel> is a channel that has been opened with C<channel_open>.

C<$exchange> is the name of the exchange to be deleted.

C<$options> is an optional hash respecting the following keys:

     {
       if_unused => $boolean,   #default 1
       nowait => $boolean,      #default 0
     }

=item queue_declare($channel, $queuename, $options)

C<$channel> is a channel that has been opened with C<channel_open>.

C<$queuename> is the name of the queuename to be instantiated.  If
C<$queuename> is undef or an empty string, then an auto generated
queuename will be used.

C<$options> is an optional hash respecting the following keys:

     {
       passive => $boolean,     #default 0
       durable => $boolean,     #default 0
       exclusive => $boolean,   #default 0
       auto_delete => $boolean, #default 1
     }

This method returns the queuename delcared (important for retrieving
the autogenerated queuename in the event that one was requested).

=item queue_bind($channel, $queuename, $exchange, $routing_key)

C<$channel> is a channel that has been opened with C<channel_open>.

C<$queuename> is a previously declared queue, C<$exchange> is a
previously declared exchange, and C<$routing_key> is the routing
key that will bind the specified queue to the specified exchange.

=item queue_unbind($channel, $queuename, $exchange, $routing_key)

This is like the C<queue_bind> with respect to arguments.  This command
unbinds the queue from the exchange.

=item publish($channel, $routing_key, $body, $options, $props)

C<$channel> is a channel that has been opened with C<channel_open>.

C<$routing_key> is the name of the routing key for this message.

C<$body> is the payload to enqueue.

C<$options> is an optional hash respecting the following keys:

     {
       exchange => $exchange,   #default 'amq.direct'
       mandatory => $boolean,   #default 0
       immediate => $boolean,   #default 0
     }

C<$props> is an optional hash (the AMQP 'props') respecting the following keys:
     {
       content_type => $string,
       content_encoding => $string,
       correlation_id => $string,
       reply_to => $string,
       expiration => $string,
       message_id => $string,
       type => $string,
       user_id => $string,
       app_id => $string,
       delivery_mode => $integer,
       priority => $integer,
       timestamp => $integer,
     }

=item consume($channel, $queuename, $options)

C<$channel> is a channel that has been opened with C<channel_open>.

C<$queuename> is the name of the queue from which we'd like to consume.

C<$options> is an optional hash respecting the following keys:

     {
       consumer_tag => $tag,    #absent by default
       no_local => $boolean,    #default 0
       no_ack => $boolean,      #default 1
       exclusive => $boolean,   #default 0
     }


The consumer_tag is returned.  This command does B<not> return AMQP
frames, it simply notifies RabbitMQ that messages for this queue should
be delivered down the specified channel.

=item recv()

This command receives and reconstructs AMQP frames and returns a hash
containing the following information:

     {
       body => 'Magic Transient Payload', # the reconstructed body
       routing_key => 'nr_test_q',        # route the message took
       exchange => 'nr_test_x',           # exchange used
       delivery_tag => 1,                 # (used for acks)
       consumer_tag => 'c_tag',           # tag from consume()
       props => $props,                   # hashref sent in
     }

C<$props> is the hash sent by publish()  respecting the following keys:
     {
       content_type => $string,
       content_encoding => $string,
       correlation_id => $string,
       reply_to => $string,
       expiration => $string,
       message_id => $string,
       type => $string,
       user_id => $string,
       app_id => $string,
       delivery_mode => $integer,
       priority => $integer,
       timestamp => $integer,
     }

=item get($channel, $queuename, $options)

C<$channel> is a channel that has been opened with C<channel_open>.

C<$queuename> is the name of the queue from which we'd like to consume.

C<$options> is an optional hash respecting the following keys:

This command runs an amqp_basic_get which returns undef immediately
if no messages are available on the queue and returns a has as follows
if a message is available.

     {
       body => 'Magic Transient Payload', # the reconstructed body
       routing_key => 'nr_test_q',        # route the message took
       exchange => 'nr_test_x',           # exchange used
       content_type => 'foo',             # (only if specified)
       delivery_tag => 1,                 # (used for acks)
       redelivered => 0,                  # if message is redelivered
       message_count => 0,                # message count
     }

=item ack($channel, $delivery_tag, $multiple = 0)

C<$channel> is a channel that has been opened with C<channel_open>.

C<$delivery_tag> the delivery tag seen from a returned frame from the
C<recv> method.

C<$multiple> specifies if multiple are to be acknowledged at once.

=item purge($channel, $queuename, $no_wait = 0)

C<$channel> is a channel that has been opened with C<channel_open>.

C<$queuename> is the queue to be purged.

C<$no_wait> a boolean specifying if the call should not wait for
the server to acknowledge the acknoledgement.

=item tx_select($channel)

C<$channel> is a channel that has been opened with C<channel_open>.

Start a server-side (tx) transaction over $channel.

=item tx_commit($channel)

C<$channel> is a channel that has been opened with C<channel_open>.

Commit a server-side (tx) transaction over $channel.

=item tx_rollback($channel)

C<$channel> is a channel that has been opened with C<channel_open>.

Rollback a server-side (tx) transaction over $channel.

=back

=cut

1;
