package Gtk2::Ex::TreeMaker;

our $VERSION = '0.01';

use strict;
use warnings;
use constant TRUE => 1;
use constant FALSE => !TRUE;
use Data::Dumper;
use Gtk2::Ex::TreeMaker::FlatInterface;

=head1 NAME

B<Gtk2::Ex::TreeMaker> - A short intro

=head1 SYNOPSIS

   use Gtk2 -init;
   use Gtk2::Ex::TreeMaker;

   # Initialize the treemaker
   my $treemaker = Gtk2::Ex::TreeMaker->new();

   # Create the column names. The first columnname has to be 'Name'
   my $column_names = [
      { ColumnName => 'Name' },
      { ColumnName => 'Nov-2003' }, { ColumnName => 'Dec-2003' }, 
      { ColumnName => 'Jan-2004' }, { ColumnName => 'Feb-2004' }
   ];

   # Here is the set of relational records to be displayed
   my $recordset = [
      ['Texas','Dallas','Fruits','Dec-2003','300'],
      ['Texas','Dallas','Veggies','Jan-2004','120'],
      ['Texas','Austin','Fruits','Nov-2003','310'],
      ['Texas','Austin','Veggies','Feb-2004','20']
   ];

   # Set the column_names first
   $treemaker->set_column_names($column_names);
   
   # Now set the data_flat using the relational records
   $treemaker->set_data_flat($recordset);
   

   # Build the model

   $treemaker->build_model;

   # Create a root window to display the widget
   my $window = Gtk2::Window->new;
   $window->signal_connect(destroy => sub { Gtk2->main_quit; });

   # Add the widget to the root window
   $window->add($treemaker->get_widget());
   
   $window->set_default_size(500, 300);
   $window->show_all;
   Gtk2->main;

=head1 DESCRIPTION

Write the story here

=head1 USER INTERACTION

May be some more details

=head1 METHODS

=head2 Gtk2::Ex::TreeMaker->new

Accepts no arguments. Just returns a reference to the object

=cut

sub new {
   my ($class) = @_;
   my $self  = {};
   $self->{data_tree} = undef;
   $self->{edited_data_flat} = [];
   $self->{data_tree_depth} = undef;
   $self->{column_names} = undef;
   $self->{frozen_column} = undef;
   $self->{tree_store_full} = undef;
   $self->{tree_store_frozen} = undef;
   $self->{tree_view_full} = undef;
   $self->{tree_view_frozen} = undef;
   $self->{chosen_column} = undef;
   bless ($self, $class);
   return $self;
}

=head2 Gtk2::Ex::TreeMaker->set_data_flat

Accepts and array of arrays as the argument. For example,

   my $recordset = [
      ['Texas','Dallas','Fruits','Dec-2003','300'],
      ['Texas','Dallas','Veggies','Jan-2004','120'],
      ['Texas','Austin','Fruits','Nov-2003','310'],
      ['Texas','Austin','Veggies','Feb-2004','20']
   ];

=cut

sub set_data_flat {
   my ($self, $data_flat) = @_;
   my $flat_interface = Gtk2::Ex::TreeMaker::FlatInterface->new();
   my $data_tree = $flat_interface->flat_to_tree($data_flat);
   $self->_set_data_tree($data_tree);  
}

# This method is temporarily not required. Will come back to it later
# Leave it in there for now
sub set_data_tree_depth {
   my ($self, $data_tree_depth) = @_;
   $self->{data_tree_depth} = $data_tree_depth;
}

# Private method
sub _set_data_tree {
   my ($self, $data_tree) = @_;
   $self->{data_tree} = $data_tree;
}

=head2 Gtk2::Ex::TreeMaker->set_column_names

The argument is an array. Each element of the array is a hash. The hash uses 'ColumnName' as the key. For example,

   my $column_names = [
      { ColumnName => 'Name' },
      { ColumnName => 'Nov-2003' }, { ColumnName => 'Dec-2003' }, 
      { ColumnName => 'Jan-2004' }, { ColumnName => 'Feb-2004' }
   ];

=cut

sub set_column_names {
   my ($self, $column_names) = @_;
   # Add an emtpy column in the end for display purposes
   push @$column_names, { ColumnName => ''};
   $self->{column_names} = $column_names;
   $self->{frozen_column} = [$column_names->[0]];
   my @tree_store_full_types = map {'Glib::String'} @{$self->{column_names}};
   my @tree_store_frozen_types = map {'Glib::String'} @{$self->{frozen_column}};
   my $tree_store_full = Gtk2::TreeStore->new(@tree_store_full_types);
   my $tree_store_frozen = Gtk2::TreeStore->new(@tree_store_frozen_types);
   $self->{tree_store_full} = $tree_store_full;
   $self->{tree_store_frozen} = $tree_store_frozen;
   my $tree_view_full = Gtk2::TreeView->new($tree_store_full);
   my $tree_view_frozen = Gtk2::TreeView->new($tree_store_frozen);
   
   #$tree_view_full->set_rules_hint(TRUE);
   #$tree_view_frozen->set_rules_hint(TRUE);
   
   _synchronize_trees($tree_view_frozen, $tree_view_full);
   $self->{tree_view_full} = $tree_view_full;
   $self->{tree_view_frozen} = $tree_view_frozen;
   $self->_create_columns ($self->{column_names}, $tree_store_full, $tree_view_full);
   # There is only one column (the first column) in this case
   my $column_name =  $self->{frozen_column}->[0]->{ColumnName};
   my $column = Gtk2::TreeViewColumn->new_with_attributes(
                     $column_name, Gtk2::CellRendererText->new(), text => 0);
   $column->set_resizable(TRUE);
   $tree_view_frozen->append_column($column);   
}

sub clear_model {
   my ($self) = @_;
   $self->{tree_store_full}->clear;
   $self->{tree_store_frozen}->clear;
}

=head2 Gtk2::Ex::TreeMaker->build_model

This is the core recursive method that actually builds the tree. 

Accepts no arguments. Returns nothing.

=cut

sub build_model {
   my ($self) = @_;
   $self->clear_model;
   _append_children($self->{tree_view_full}->get_model(), undef, 
                                    $self->{data_tree}, $self->{column_names});  
   _append_children($self->{tree_view_frozen}->get_model(), undef, 
                                    $self->{data_tree}, $self->{frozen_column}); 
   # Expand the tree to start with
   $self->{tree_view_frozen}->expand_all;
}

=head2 Gtk2::Ex::TreeMaker->get_widget

Returns the widget that you can later attach to a root window or any other container.

=cut

sub get_widget {
   my ($self) = @_;
   # Add the frozen-tree to the left side of the pane 
   my $display_paned = Gtk2::HPaned->new;
   $display_paned->add1 ($self->{tree_view_frozen});

   # we set the vertical size request very small, and it will fill up the
   # available space when we set the default size of the window.
   $self->{tree_view_frozen}->set_size_request (-1, 10);

   # Add the full-tree to a scrolled window in the right pane
   my $scroll = Gtk2::ScrolledWindow->new;
   $scroll->add ($self->{tree_view_full});
   $display_paned->add2 ($scroll);

   # Synchronize the scrolling
   $self->{tree_view_frozen}->set(vadjustment => $self->{tree_view_full}->get_vadjustment);
   
   return $display_paned;
}

# Private method to enable the freezepane.
sub _synchronize_trees {
   my ($tree_view_frozen, $tree_view_full) = @_;

   # First, we will synchronize the row-expansion/collapse
   $tree_view_frozen->signal_connect('row-expanded' =>
            sub {
               my ($view, $iter, $path) = @_;
               $tree_view_full->expand_row($path,0);
            }
            ); 
   $tree_view_frozen->signal_connect('row-collapsed' =>
            sub {
               my ($view, $iter, $path) = @_;
               $tree_view_full->collapse_row($path);
            }
            ); 

   # Next, we will synchronize the row selection
   $tree_view_frozen->get_selection->signal_connect('changed' =>
            sub {
               my ($selection) = @_;
               _synchronize_tree_selection($tree_view_frozen, $tree_view_full, $selection);
            }
            ); 
   $tree_view_full->get_selection->signal_connect('changed' =>
            sub {
               my ($selection) = @_;
               _synchronize_tree_selection($tree_view_full, $tree_view_frozen, $selection);
            }
            ); 
}


# Synchronize the tree selections
sub _synchronize_tree_selection {
   my ($thisview, $otherview, $this_selection) = @_;
   return unless ($thisview and $otherview and $this_selection);
   my ($selected_model, $selected_iter) = $this_selection->get_selected;
   return unless ($selected_model and $selected_iter);
   $otherview->get_selection->select_path ($selected_model->get_path($selected_iter));
}

sub _append_children {
   my ($tree_store, $iter, $data_tree, $columns) = @_;
   if ($data_tree) {    
      my $count = 0;    
      my $child_iter = $tree_store->append ($iter);
      for my $column(@$columns) {
         my $column_name = $column->{ColumnName};
         if ($data_tree->{$column_name}) {
            $tree_store->set($child_iter, $count, $data_tree->{$column_name});
         }
         $count++;
      }
      foreach my $child(@{$data_tree->{'Node'}}) {
         _append_children($tree_store, $child_iter, $child, $columns);
      }
   }
}

sub _create_columns {
   my ($self, $all_columns, $tree_store, $tree_view )=@_;
   my $column_count = 0;
   for my $column (@$all_columns) {
      my $column_name =  $column->{ColumnName};
      my $cell = Gtk2::CellRendererText->new;
      
      # Align all cells to the right
      $cell->set (xalign => 1);
      
      # Make all cells editable. We will probably add some logic here later on.
      $cell->set (editable => TRUE);      
      #$cell->set (editable => TRUE) if $column_count % 3; # Some stupid logic.
      
      # Create a new variable.
      # Else it will always be set to max value of column_count
      # Reference issues
      my $column_id = $column_count;
      
      # Handle the edits. This is currently half baked.
      $cell->signal_connect (edited => 
         sub {
               my ($cell, $pathstring, $newtext) = @_;
               my $path = Gtk2::TreePath->new_from_string ($pathstring);
               my $iter = $tree_store->get_iter ($path);
               $tree_store->set ($iter, $column_id, $newtext);
               
               # Do something if data changes
               #$self->_record_changes($path,$column_id, $newtext);
               
               # This needs to be worked on
               #modify_xml ($path,$column_being_edited, $newtext);
         });
      
      my $column = Gtk2::TreeViewColumn->new_with_attributes(
         $column_name, $cell, text => $column_count);
      $column->set_resizable(TRUE);
      $tree_view->append_column($column);


      # Hide the first column
      # Ensure that the expander is fixed to the first column 
      # (and hence is hidden too)
      if ($column_count == 0) {
         $column->set_visible(FALSE);
         $tree_view->set_expander_column($column);
      }
      $column_count++;
   }
}

# This method is temporarily out of service.
# We will revive this later
sub _record_changes {
   my ($self, $edit_path, $column_id, $newtext) = @_;
   my @tree_path = split /:/, $edit_path->to_string;
   my @record;
   for (my $i=0; $i<$self->{data_tree_depth}+2; $i++) {
      $record[$i] = undef;
   }
   shift @tree_path;
   my $sub_data_tree = $self->{data_tree};
   $record[0] = $sub_data_tree->{Name};
   my $count = 1;
   foreach my $node (@tree_path) {
      $sub_data_tree = $sub_data_tree->{Node}->[$node];
      $record[$count++] = $sub_data_tree->{Name};
   }
   $record[-2] = $self->{column_names}->[$column_id]->{ColumnName};
   $record[-1] = $newtext;
   push @{$self->{edited_data_flat}}, \@record;
}

1;

__END__

=head1 TODO

Here is a list of stuff that I plan to add to this module.

=over 4

=item * Do something when cells are edited

Probably, provide a callback hook for a sub that can be called when cells are edited. This sub can be responsible for caching all the changes and then applying it back to source data when a "SAVE" button is pressed, for example. 

=item * Not all cells need to be editable

Provide some kind of criteria to decide whether a cell should be editable or not.

=item * Some cells may need to be "hyperlinked"

Some of the cells may have to be made clickable (hyperlinks). When clicked, may be the cell can drop down a menu or lead you to another view. Provide a callback on click (or rightclick) on the cells.

=back

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