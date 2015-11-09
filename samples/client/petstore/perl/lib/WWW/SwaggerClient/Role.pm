package WWW::SwaggerClient::Role;
use utf8;

use Moose::Role;
use namespace::autoclean;
use Class::Inspector;
use Log::Any qw($log);
use WWW::SwaggerClient::ApiFactory;

requires 'auth_setup_handler';

has base_url => ( is => 'ro',
			 	  required => 0,
			 	  isa => 'Str',
			 	  );

has api_factory => ( is => 'ro',
					 isa => 'WWW::SwaggerClient::ApiFactory',
					 builder => '_build_af', 
					 lazy => 1,
					 );
					 
sub BUILD {
	my $self = shift;
	
	# ignore these symbols imported into API namespaces
	my %outsiders = map {$_ => 1} qw( croak );
	
	my %delegates;
	
	# collect the methods callable on each API
	foreach my $api_name ($self->api_factory->apis_available) {
		my $api_class = $self->api_factory->classname_for($api_name);
		my $methods = Class::Inspector->methods($api_class, 'expanded');
		my @local_methods = grep {! /^_/} grep {! $outsiders{$_}} map {$_->[2]} grep {$_->[1] eq $api_class} @$methods;
		push( @{$delegates{$_}}, {api_name => $api_name, api_class => $api_class} ) for @local_methods;			
	}
	
	# remove clashes
	foreach my $method (keys %delegates) {
		if ( @{$delegates{$method}} > 1 ) {
			my ($apis) = delete $delegates{$method};
			foreach my $api (@$apis) {
				warn sprintf "Cannot delegate %s (use \$self->%s_api->%s instead)\n", $method, lc($api->{api_name}), $method;
			}
		}
	}
	
	# build the flattened API
	foreach my $api_name ($self->api_factory->apis_available) {
		my $att_name = sprintf "%s_api", lc($api_name);
		my $api_class = $self->api_factory->classname_for($api_name);
		my @delegated = grep { $delegates{$_}->[0]->{api_name} eq $api_name } keys %delegates;
		$log->debugf("Adding API: '%s' handles %s", $att_name, join ', ', @delegated);
		$self->meta->add_attribute( $att_name => ( 
									is => 'ro',
									isa => $api_class,
									default => sub {$self->api_factory->get_api($api_name)},
									lazy => 1,
									handles => \@delegated,
									) );
	}
}

sub _build_af {
	my $self = shift;
	my %args = ( auth_setup_handler_object => $self );
	$args{base_url} = $self->base_url if $self->base_url;
	return WWW::SwaggerClient::ApiFactory->new(%args);
}

=head1 NAME

WWW::SwaggerClient::Role - a Moose role for the Perl Swagger Codegen project

=head2 A note on Moose

This role is the only component of the library that uses Moose. See 
WWW::SwaggerClient::ApiFactory for non-Moosey usage. 

=head1 SYNOPSIS

The Perl Swagger Codegen project builds a library of Perl modules to interact with 
a web service defined by a Swagger specification. See below for how to build the 
library.

This module provides an interface to the generated library. All the classes, 
objects, and methods (well, not quite *all*, see below) are flattened into this 
role. 

	package MyApp;
	use Moose;
	has [qw(username password)] => ( is => 'ro', required => 1, isa => 'Str' );
	with 'WWW::SwaggerClient::Role';
	sub auth_setup_handler {...}
	
	package main;
	
	my $api = MyApp->new({username => $username, password => $password});
	
	my $pet = $api->get_pet_by_id(pet_id => $pet_id);
	
Notice that you need to provide the code to accept the parameters passed in to C<new()>
(by setting up attributes via the C<has> keyword). They should be used by 
C<auth_setup_handler()> to configure authentication (see below). 

=head2 Structure of the library

The library consists of a set of API classes, one for each endpoint. These APIs
implement the method calls available on each endpoint. 

Additionally, there is a set of "object" classes, which represent the objects 
returned by and sent to the methods on the endpoints. 

An API factory class is provided, which builds instances of each endpoint API. 

This Moose role flattens all the methods from the endpoint APIs onto the consuming 
class. It also provides methods to retrieve the endpoint API objects, and the API 
factory object, should you need it. 

For documentation of all these methods, see AUTOMATIC DOCUMENTATION below.

=head1 METHODS

=head2 C<auth_setup_handler()>

This method is NOT provided - you must write it yourself. Its task is to configure 
authentication for each request. 

The method is called on your C<$api> object and passed the following parameters:

=over 4

=item C<header_params>

A hashref that will become the request headers. You can insert auth 
parameters.

=item C<query_params>

A hashref that will be encoded into the request URL. You can insert auth 
parameters.

=item C<auth_settings>

TODO.

=item C<api_client>

A reference to the C<WWW::SwaggerClient::ApiClient> object that is responsible 
for communicating with the server. 

=back

For example: 

	sub auth_setup_handler {
		my ($self, %p) = @_;
		$p{header_params}->{'X-TargetApp-apiKey'} = $api_key;
		$p{header_params}->{'X-TargetApp-secretKey'} = $secret_key;
	}

=head2 base_url

The generated code has the C<base_url> already set as a default value. This method 
returns (and optionally sets) the current value of C<base_url>.

=head2 api_factory

Returns an API factory object. You probably won't need to call this directly. 

	$self->api_factory('Pet'); # returns a WWW::SwaggerClient::PetApi instance
	
	$self->pet_api;            # the same

=head1 MISSING METHODS

Most of the methods on the API are delegated to individual sub-API objects (e.g. 
Pet API, Store API, User API etc). Where different sub-APIs use the same method 
name (e.g. C<new()>), these methods can't be delegated. So you need to call 
C<$api-E<gt>pet_api-E<gt>new()>. 

In principle, every API is susceptible to the presence of a few, random, undelegatable 
method names. In practice, because of the way method names are constructed, it's 
unlikely in general that any methods will be undelegatable, except for: 

	new()
	class_documentation()
	method_documentation()

To call these methods, you need to get a handle on the relevant object, either 
by calling C<$api-E<gt>foo_api> or by retrieving an object, e.g. 
C<$api-E<gt>get_pet_by_id(pet_id =E<gt> $pet_id)>.

=head1 BUILDING YOUR LIBRARY

See the homepage C<https://github.com/swagger-api/swagger-codegen> for full details. 
But briefly, clone the git repository, build the codegen codebase, set up your build 
config file, then run the API build script. You will need git, Java 7 and Apache 
maven 3.0.3 or better already installed.

The config file should specify the project name for the generated library: 

	{"moduleName":"MyProjectName"}

Your library files will be built under C<WWW::MyProjectName>.

	$ git clone https://github.com/swagger-api/swagger-codegen.git
	$ cd swagger-codegen
	$ mvn package
	$ java -jar modules/swagger-codegen-cli/target/swagger-codegen-cli.jar generate \
  -i [URL or file path to JSON swagger API spec] \
  -l perl \
  -c /path/to/config/file.json \
  -o /path/to/output/folder

Bang, all done. Run the C<autodoc> script in the C<bin> directory to see the API 
you just built. 

=head1 AUTOMATIC DOCUMENTATION

You can print out a summary of the generated API by running the included 
C<autodoc> script in the C<bin> directory of your generated library.
	
=head1 DOCUMENTATION FROM THE SWAGGER SPEC

Additional documentation for each class and method may be provided by the Swagger 
spec. If so, this is available via the C<class_documentation()> and 
C<method_documentation()> methods on each generated API and class: 

	my $cdoc = $api->pet_api->class_documentation;                   
	my $cmdoc = $api->pet_api->method_documentation->{$method_name}; 
	
	my $odoc = $api->get_pet_by_id->(pet_id => $pet_id)->class_documentation;                  
	my $omdoc = $api->get_pet_by_id->(pet_id => $pet_id)->method_documentation->{method_name}; 
	
Each of these calls returns a hashref with various useful pieces of information. 	

=cut

1;
