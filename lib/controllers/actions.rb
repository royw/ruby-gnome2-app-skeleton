##
# The action descriptions are grouped here for easier maintenance.
# Most of the actions are created in MainController
module Actions
  ACTIONS = {
    :NewAction =>
      {
        :label   => '_New',
        :tooltip => 'Create a new cog',
        :stock   => Gtk::Stock::NEW,
        :accel   => '<control>N'
      },
    :QuitAction =>
      {
        :label   => '_Quit',
        :tooltip => 'Quit the application',
        :stock   => Gtk::Stock::QUIT,
        :accel   => '<control>Q'
      },
    :SaveAction =>
      {
        :label   => '_Save',
        :tooltip => 'Save the cogs',
        :stock   => Gtk::Stock::SAVE,
        :accel   => ''
      },
    :OpenAction =>
      {
        :label   => '_Open',
        :tooltip => 'Open the cogs',
        :stock   => Gtk::Stock::OPEN,
        :accel   => ''
      },
    :EditAction =>
      {
        :label   => '_Edit',
        :tooltip => "Edit the cog",
        :stock   => Gtk::Stock::EDIT,
        :accel   => '<control>E'
      },
    :DeleteAction =>
      {
        :label   => '_Delete',
        :tooltip => "Delete the cog",
        :stock   => Gtk::Stock::DELETE,
        :accel   => ''
      },
    :CopyAction =>
      {
        :label   => '_Copy',
        :tooltip => "Copy the cog to the clipboard",
        :stock   => Gtk::Stock::COPY,
        :accel   => '<control>C'
      },
    :SelectAction =>
      {
        :label   => 'Se_lect',
        :tooltip => "Select the cog",
        :stock   => Gtk::Stock::EXECUTE,
        :accel   => ''
      },
    :OptionOneAction =>
      {
        :label   => 'Option One',
        :tooltip => "Option One",
        :stock   => Gtk::Stock::JUSTIFY_LEFT,
        :accel   => '',
        :value   => 1
      },
    :OptionTwoAction =>
      {
        :label   => 'Option Two',
        :tooltip => "Option Two",
        :stock   => Gtk::Stock::JUSTIFY_RIGHT,
        :accel   => '',
        :value   => 2
      },

  }
end

