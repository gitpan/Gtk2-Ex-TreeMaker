use strict;
use warnings;
use Data::Dumper;
use Gtk2 -init;
use constant TRUE => 1;
use constant FALSE => !TRUE;

use Gtk2::Ex::TreeMaker;

# Initialize our new widget
my $treemaker = Gtk2::Ex::TreeMaker->new();

# Create an array to contain the column_names. These names appear as the header for each column.
# The entries of the arrays should be hashes. Each has should use 'ColumnName' as the key.
# Also, for now, please choose the first ColumnName => 'Name'
my $column_names = [
   { ColumnName => 'Name' },
   { ColumnName => 'Nov-2003' }, { ColumnName => 'Dec-2003' }, { ColumnName => 'Jan-2004' },
   { ColumnName => 'Feb-2004' }, { ColumnName => 'Mar-2004' }, { ColumnName => 'Apr-2004' },
   { ColumnName => 'May-2004' }, { ColumnName => 'Jun-2004' }, { ColumnName => 'Jul-2004' }
];

# Create a recordset as an array of arrays
my @recordset;
while(<DATA>) {
   chomp;
   my @record = split /\,/, $_;
   push @recordset, \@record;
}

# First set the column_names. Do this before doing anything else
$treemaker->set_column_names($column_names);

# We will inject our relational recordset into the new widget
$treemaker->set_data_flat(\@recordset);

# Actually build the model. The recursice wheels are turing right now
$treemaker->build_model;

# That's it. Now just create a new root window to add our new widget into.
my $window = Gtk2::Window->new;
$window->signal_connect(destroy => sub { Gtk2->main_quit; });

# Add it here.
my $treemaker_widget = $treemaker->get_widget();
$window->add($treemaker_widget);

$window->set_default_size(500, 300);
$window->show_all;
Gtk2->main;

__DATA__
Texas,Dallas,Fruits,Dec-2003,300
Texas,Dallas,Veggies,Jan-2004,120
Texas,Austin,Fruits,Nov-2003,310
Texas,Austin,Veggies,Feb-2004,20
Texas,Austin,Veggies,Jun-2004,80
