package DBIx::NoSQL;
# ABSTRACT: Experimental NoSQL-ish overlay for an SQL database

use strict;
use warnings;

use Any::Moose;
use Try::Tiny;

use JSON;
eval { require JSON::XS; };
our $json = JSON->new->pretty;
sub json { $json }

use DBIx::NoSQL::EntitySource;

has dbh => qw/ is rw /;
has _source => qw/ is ro lazy_build 1 /;
sub _build__source { {} }

sub source {
    my $self = shift;
    my $moniker = shift or die "Missing moniker";

    return $self->_source->{$moniker} ||= DBIx::NoSQL::EntitySource->new(
        store => $self, moniker => $moniker );
}

sub transact {
    my $self = shift;
    my $code = shift;

    my $dbh = $self->dbh;
    try {
        $dbh->begin_work;
        $code->();
        $dbh->commit;
    }
    catch {
        try { $dbh->rollback }
    }
}

1;

__END__

sub search {
    my $self = shift;
    my $moniker = shift or die "Missing moniker";

    return DBIx::NoSQL::ResultSet->new( source => $self->source( $moniker ) );
}

sub put {
    my $self = shift;
    my $source_name = shift;

    die "Missing source" unless $source_name;
    my $source = $self->source( $source_name ) or die "Invalid source ($source_name)";
    return $source->put( @_ );
}

sub set {
    my $self = shift;
    my $source_name = shift;

    die "Missing source" unless $source_name;
    my $source = $self->source( $source_name ) or die "Invalid source ($source_name)";
    return $source->set( @_ );
}


#sub set {
#    my $self = shift;
#    my $target = shift or die "Missing target";
#    my $data = shift;

#    my ( $source, $_target );
#    if ( ! ref $target ) {
#        $source = $self->source( $target );
#    }
#    elsif ( ref $target eq 'ARRAY' ) {
#        $source = $self->source( $target->[0] );
#        $_target = $target->[1];
#    }
#    elsif ( blessed $target && $target->isa( 'DBIx::NoSQL::ResultSet' ) ) {
#        $source = $target->source;
#    }

#    return $source->set( $_target, $data );
#}

1;
