package Gtk2::Ex::TreeMaker::FlatInterface;

our $VERSION = '0.01';

use strict;
use warnings;
use Data::Dumper;

=head1 NAME

B<Gtk2::Ex::TreeMaker::FlatInterface> - This module is not to be used directly. It is called from Gtk2::Ex::TreeMaker as a utility module.

=head1 DESCRIPTION

This module contains a utility method C<sub flat_to_tree>. This utility method will accept an array of arrays (a set of relational records) as its input and then return a treelike data structure that is in-turn used by the Gtk2::Ex::TreeMaker to spin the Gtk2::TreeModel.

=head1 METHODS

=head2 Gtk2::Ex::TreeMaker::FlatInterface->new

Accepts no arguments. Just returns a reference to the object

=cut

sub new {
   my ($class) = @_;
   my $self  = {};
   bless ($self, $class);
   return $self;
}

=head2 Gtk2::Ex::TreeMaker::FlatInterface->flat_to_tree

Accepts an array of arrays (a set of relational records) as its input. Returns a special tree-like data structure that is then used by the Gtk2::Ex::TreeMaker to spin the Gtk2::TreeModel.

Here is a sample input:

   my $input = [
      ['Texas','Dallas','Fruits','Dec-2003','300'],
      ['Texas','Dallas','Veggies','Jan-2004','120'],
      ['Texas','Austin','Fruits','Nov-2003','310'],
      ['Texas','Austin','Veggies','Feb-2004','20']
   ];

Here is the corresponding output:

   my $output = {
             'Node' => [
                         {
                           'Node' => [
                                       {
                                         'Feb-2004' => '20',
                                         'Jun-2004' => '80',
                                         'Name' => 'Veggies'
                                       },
                                       {
                                         'Nov-2003' => '310',
                                         'Name' => 'Fruits'
                                       }
                                     ],
                           'Name' => 'Austin'
                         },
                         {
                           'Node' => [
                                       {
                                         'Jan-2004' => '120',
                                         'Name' => 'Veggies'
                                       },
                                       {
                                         'Dec-2003' => '300',
                                         'Name' => 'Fruits'
                                       }
                                     ],
                           'Name' => 'Dallas'
                         }
                       ],
             'Name' => 'Texas'
           };

This data structure is really the key input into the Gtk2::Ex::TreeMaker module. If you can provide this data structure through external means, then we can build Gtk2::Ex::TreeMaker using that. More on this later...

=cut

sub flat_to_tree {
   my ($self, $flat) = @_;
   my $intermediate = _flat_to_intermediate($flat);
   my $tree = _intermediate_to_tree($intermediate);
   return $tree;
}

# This is a private method
sub _flat_to_intermediate {
   my ($flat) = shift;
   my $intermediate = {};  
   foreach my $record (@$flat) {
      my $sub_intermediate = $intermediate;
      foreach (my $i=0; $i<=$#{@$record}-2; $i++){
         my $column = $record->[$i];
         next unless $column;
         if (!exists $sub_intermediate->{$column}) {
            $sub_intermediate->{$column} = {};
         }
         $sub_intermediate = $sub_intermediate->{$column};        
      }
      if ($record->[-2]) {
         $sub_intermediate->{$record->[-2]} = $record->[-1];      
      }
   }
   return $intermediate;
}

# This is a private method
sub _intermediate_to_tree {
   my ($intermediate) = shift;
   foreach my $singlekey ( keys %$intermediate) {
      my $node = {};
      $node->{'Name'} = $singlekey;
      foreach my $key (keys %{$intermediate->{$singlekey}}) {
         if (ref ($intermediate->{$singlekey}->{$key}) eq 'HASH') {
            $node->{'Node'} = [] unless ($node->{'Node'});
            my $newtree = {};
            $newtree->{$key} = $intermediate->{$singlekey}->{$key};
            push @{$node->{'Node'}}, _intermediate_to_tree($newtree);
         } else {
            $node->{$key} = $intermediate->{$singlekey}->{$key};
         }
      }
      return $node;
   }
}

1;

__END__

=head1 AUTHOR

Ofey Aikon, C<< <ofey_aikon@yahoo.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-gtk2-ex-recordsfilter@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2004 Ofey Aikon, All Rights Reserved.

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Library General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Library General Public License for more
details.

You should have received a copy of the GNU Library General Public License along
with this library; if not, write to the Free Software Foundation, Inc., 59
Temple Place - Suite 330, Boston, MA  02111-1307  USA.

=cut