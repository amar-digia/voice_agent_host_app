/// The UI tools Claude may call. They run inside the Flutter app; the server
/// only defines them and checks every call against these schemas.
///
/// Keep the names in sync with `lib/ai/ai_tool_executor.dart` in the app.
library;

const screenIds = [
  'home',
  'markets',
  'portfolio',
  'orders',
  'account',
  'profile_form',
  'back',
];

Map<String, dynamic> _schema(Map<String, Map<String, dynamic>> properties) => {
  'type': 'object',
  'properties': properties,
  'required': properties.keys.toList(),
  'additionalProperties': false,
};

const _widgetId = {
  'type': 'string',
  'description': 'A widget id from the latest get_visible_widgets result.',
};
const _formId = {
  'type': 'string',
  'description': 'A form id from get_current_screen.',
};

final List<Map<String, dynamic>> toolDefinitions = [
  _tool(
    'get_current_screen',
    'Returns the screen the user is on, the forms on it, any open sheet or '
        'dialog, the screens you can navigate to (and which are implemented), '
        'and app messages shown since the last check.',
    {},
  ),
  _tool(
    'get_visible_widgets',
    'Lists every registered widget on the current screen with its id, kind, '
        'label, value (when it may be shared), enabled state and the actions '
        'you are permitted to perform on it.',
    {},
  ),
  _tool(
    'get_widget_state',
    'Returns the full state of one widget: value, options, validation error, '
        'whether it is required, and the permitted actions.',
    {'widget_id': _widgetId},
  ),
  _tool('fill_field', 'Replaces the whole content of a text field.', {
    'widget_id': _widgetId,
    'text': {'type': 'string', 'description': 'The complete new value.'},
  }),
  _tool(
    'select_option',
    'Chooses an option of a dropdown or choice widget (radio buttons, tabs, '
        'segmented controls).',
    {
      'widget_id': _widgetId,
      'option': {'type': 'string', 'description': 'One of the listed options.'},
    },
  ),
  _tool('set_checkbox', 'Checks or unchecks a checkbox.', {
    'widget_id': _widgetId,
    'checked': {'type': 'boolean'},
  }),
  _tool('set_date', 'Sets a date field.', {
    'widget_id': _widgetId,
    'date': {'type': 'string', 'description': 'The date as YYYY-MM-DD.'},
  }),
  _tool('tap_widget', 'Taps a button. Returns the resulting screen.', {
    'widget_id': _widgetId,
  }),
  _tool(
    'navigate_to_screen',
    'Opens a screen, or goes back with "back". Fails honestly for screens '
        'that are not implemented yet.',
    {
      'screen_id': {'type': 'string', 'enum': screenIds},
    },
  ),
  _tool(
    'validate_form',
    'Runs the form\'s own validation, shows the errors in the app, and '
        'returns them with any missing required fields.',
    {'form_id': _formId},
  ),
  _tool(
    'submit_form',
    'Validates and submits a form. Forms that save data ask the user to '
        'confirm in the app first; a declined confirmation is reported back.',
    {'form_id': _formId},
  ),
];

Map<String, dynamic> _tool(
  String name,
  String description,
  Map<String, Map<String, dynamic>> properties,
) => {
  'name': name,
  'description': description,
  'strict': true,
  'input_schema': _schema(properties),
};

final Map<String, Map<String, dynamic>> _schemasByName = {
  for (final tool in toolDefinitions)
    tool['name'] as String: tool['input_schema'] as Map<String, dynamic>,
};

bool isKnownTool(String name) => _schemasByName.containsKey(name);

/// Checks [input] against the tool's schema. Returns an error or null.
///
/// Strict tool use already constrains Claude's output; this is the server's
/// own check before anything is sent to the app.
String? validateToolInput(String name, Object? input) {
  final schema = _schemasByName[name];
  if (schema == null) return 'Unknown tool "$name".';
  if (input is! Map) return 'Tool input must be an object.';

  final properties = schema['properties'] as Map<String, dynamic>;
  for (final key in input.keys) {
    if (!properties.containsKey(key)) return 'Unexpected argument "$key".';
  }
  for (final entry in properties.entries) {
    final value = input[entry.key];
    final spec = entry.value as Map<String, dynamic>;
    if (value == null) return 'Missing argument "${entry.key}".';
    switch (spec['type']) {
      case 'string':
        if (value is! String) return '"${entry.key}" must be a string.';
        if (value.length > 1000) return '"${entry.key}" is too long.';
        final allowed = spec['enum'] as List?;
        if (allowed != null && !allowed.contains(value)) {
          return '"${entry.key}" must be one of ${allowed.join(', ')}.';
        }
      case 'boolean':
        if (value is! bool) return '"${entry.key}" must be true or false.';
    }
  }
  return null;
}
