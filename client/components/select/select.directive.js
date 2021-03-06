angular.module('probedock.select')

// Select directives
.directive('simpleSelect', function() { return createSelectDirective('SimpleSelectCtrl', defaultsAttributes); })
.directive('categorySelect', function() { return createSelectDirective('CategorySelectCtrl', defaultsAttributes); })
.directive('organizationSelect', function() { return createSelectDirective('OrganizationSelectCtrl', _.extend(defaultsAttributes, {
    administered: '=?', // Retrieve the organization where the signed user is admin
    onlyActive: '=?'    // Retrieve only the active organizations, if false, all the organizations are retrieved
  }));
})
.directive('projectSelect', function() { return createSelectDirective('ProjectSelectCtrl', defaultsAttributes); })
.directive('projectVersionSelect', function() {
  return createSelectDirective('ProjectVersionSelectCtrl', _.extend(defaultsAttributes, {
    project: '=?',        // Allow to filter the choices based on the versions of a specific project
    test: '=?',           // Allow to filter the choices based on the versions of a specific test
    latestVersion: '=',   // Allow to set the most recent version
    uniqueBy: '@'         // Use to force a uniq criteria in case this select is used to show versions for multiple projects
  }));
})
.directive('userSelect', function() { return createSelectDirective('UserSelectCtrl', defaultsAttributes); })

// Select controllers
.controller('SimpleSelectCtrl', function(api, $scope) {
  setupController($scope, api, { defaults: {} });
})
.controller('CategorySelectCtrl', function(api, $scope) {
  setupController($scope, api, {
    defaults: {
      modelProperty: defaultModelProperty($scope, 'categoryName', 'category'),
      label: 'Filter by category',
      placeholder: 'All categories',
      labelNew: 'create new category',
      extract: 'name'
    },
    fetchUrl: '/categories'
  });
}).controller('OrganizationSelectCtrl', function(api, $scope, orgNameFilter) {
  // Always disable the create new feature on organization select
  $scope.createNew = false;

  setupController($scope, api, {
    defaults: {
      modelProperty: defaultModelProperty($scope, 'organizationId', 'organization'),
      label: 'Filter by organization',
      placeholder: 'All organizations',
      administered: false,
      onlyActive: true
    },
    fetchUrl: '/organizations',

    formatItem: function(organization) {
      // Apply the org name filter
      return orgNameFilter(organization);
    },

    handleParams: function($scope, params) {
      // Set the param only if true, if false, we do not want to filter by administered
      if ($scope.administered) {
        params.administered = 1;
      }

      // Force to retrieve the active organizations only if set to true, otherwise return all organizations
      if ($scope.onlyActive) {
        params.active = 1;
      }

      return params;
    }
  });
}).controller('ProjectSelectCtrl', function(api, $scope, projectNameFilter) {
  setupController($scope, api, {
    defaults: {
      modelProperty: defaultModelProperty($scope, 'projectId', 'project'),
      label: 'Filter by project',
      placeholder: 'All projects',
      labelNew: 'create new project'
    },
    fetchUrl: '/projects',

    formatItem: function(project) {
      // Apply the project name filter
      return projectNameFilter(project);
    }
  });
}).controller('ProjectVersionSelectCtrl', function(api, $scope, projectVersions) {
  setupController($scope, api, {
    defaults: {
      modelProperty: defaultModelProperty($scope, 'projectVersionId', 'projectVersion'),
      label: 'Filter by version',
      labelNew: 'create new version',
      placeholder: $scope.placeholder ? $scope.placeholder : ($scope.latestVersion ? 'Latest version: ' + $scope.latestVersion.name : 'All versions'),
      defaultNewItem: '1.0.0'
    },
    fetchUrl: '/projectVersions',

    handleParams: function($scope, params) {
      // Specific project filter
      if ($scope.project) {
        params.projectId = $scope.project.id;
      }

      // Specific test filter
      if ($scope.test) {
        params.testId = $scope.test.id;
      }

      return params;
    },

    processResults: function(res) {
      // Process the choices
      var projectVersionChoices;

      // When the versions are retrieved for multiple projects, we want make sure to keep only one version based on specific attribute
      if ($scope.uniqueBy) {
        projectVersionChoices = _.uniq(res.data, function(projectVersion) { return projectVersion[$scope.uniqueBy]; });
      } else {
        projectVersionChoices = res.data;
      }

      // Use a semantic like algorithm to sort the versions
      return projectVersions.sort(projectVersionChoices);
    }
  })
}).controller('UserSelectCtrl', function(api, $scope) {
  // Always disable the create new feature on user select
  $scope.createNew = false;

  setupController($scope, api, {
    defaults: {
      modelProperty: defaultModelProperty($scope, 'userId', 'user'),
      label: 'Filter by user',
      placeholder: 'All users',
      extract: 'id'
    },
    fetchUrl: '/users'
  });
});

/**
 * Define the default attributes that the *-select directive have at least
 */
var defaultsAttributes = {
  organization: '=',     // The organization for data scoping
  selectChoices: '=?',   // Force to use an external list of choices rather than fetching it from an API call
  modelObject: '=',      // The model object relates to an object where the selected values will be stored
  modelProperty: '@',    // Property name on the model object to store the selected values
  prefix: '@',           // Prefix to created unique HTML IDs for labels and select fields
  createNew: '=?',       // Enable the possibility to create a new item
  autoSelect: '=?',      // Do an automatic selection on the first item when no other value is provided through the model object
  placeholder: '@',      // Placeholder text shown in the select field
  label: '@',            // The label text associated with the select field
  noLabel: '=?',         // When set to true, the label is not shown
  multiple: '=?',        // Switch between single and multiple select field
  extract: '@',          // Name of the property to extract and use in the select field (Ex: id)
  allowClear: '=?',      // Enable the possibility to remove a selection
  labelNew: '@',         // The label text for the creation of a new item
  defaultNewItem: '@',   // The default text value for the creation of a new item
  displayedProperty: '@' // Attribute name to use to show the item in the select field
};

/**
 * Define the standard default values for the select directive
 */
var defaults = {
  displayedProperty: 'name', // Attribute name to use to show the item in the select field
  allowClear: true,          // It is allowed to unselect items
  multiple: false,           // She select fields are single selection
  noLabel: false,            // The label is visible
  extract: 'id'              // Use the ID to identify items
};

/**
 * Create standard select directive
 *
 * @param controllerName The controller name to manage the directive
 * @param attributes The attributes to configure the directive
 * @returns The directive
 */
function createSelectDirective(controllerName, attributes) {
  return {
    restrict: 'E',
    controller: controllerName,
    templateUrl: '/templates/components/select/select.template.html',
    scope: attributes
  };
}

/**
 * Configure a controller for a select directive
 *
 * @param $scope The scope
 * @param api The API service
 * @param options The options for the controller configuration
 */
function setupController($scope, api, options) {
  if (!$scope.prefix) {
    throw new Error("Prefix must be provided.");
  } else if (!options) {
    throw new Error("Options must be provided.");
  } else if (!options.defaults) {
    throw new Error("Defaults must be provided.");
  } else if (!options.fetchUrl && !$scope.selectChoices) {
    throw new Error("FetchUrl must be provided.");
  }

  // Setup the default options and values for the controller
  _.defaults($scope, _.extend({
    config: {
      newItem: false
    },
    choices: $scope.selectChoices ? $scope.selectChoices : []
  }, _.defaults(options.defaults, defaults)));

  $scope.$watch('config.newItem', function(value) {
    if (value) {
      var previousItem = $scope.modelObject[$scope.modelProperty];
      // create a new object if a new item is to be created
      $scope.modelObject[$scope.modelProperty] = {};
      // pre-fill it with either the previously selected item, or with a default new item value
      $scope.modelObject[$scope.modelProperty] = previousItem ? previousItem : $scope.defaultNewItem;
    } else if (value === false && $scope.choices.length && $scope.autoSelect) {
      // auto-select the first existing item when disabling creation of a new item
      $scope.modelObject[$scope.modelProperty] = $scope.itemExtract($scope.choices[0]);
    }
  });

  // Define a function to show the item value in the select. If no function
  // is defined, a lookup on a property given by displayedProperty is done.
  if (options.formatItem) {
    $scope.formatItem = options.formatItem;
  } else {
    $scope.formatItem = function(item) {
      return item ? item[$scope.displayedProperty] : '';
    };
  }

  // Extract the item property or item itself
  $scope.itemExtract = function(item) {
    if (item) {
      return $scope.extract == '@model' ? item : item[$scope.extract];
    } else {
      return '';
    }
  };

  $scope.fetchChoices = function(search) {
    if (!$scope.selectChoices) {
      var params = {};

      // Always scope by organization
      if ($scope.organization) {
        params.organizationId = $scope.organization.id;
      }

      // Add search param if available
      if (search) {
        params.search = search;
      }

      // Process additional parameters if required
      if (options.handleParams) {
        params = options.handleParams($scope, params);
      }

      // Do the API call
      api({
        url: options.fetchUrl,
        params: params
      }).then(function (res) {
        // Check if there is any results processing to do
        if (options.processResults) {
          $scope.choices = options.processResults(res);
        } else {
          $scope.choices = res.data;
        }

        if ($scope.choices.length && $scope.autoSelect) {
          // if items are found, automatically select the first one
          $scope.modelObject[$scope.modelProperty] = $scope.itemExtract($scope.choices[0]);
        } else if (!$scope.choices.length && $scope.createNew) {
          // if there are no existing items and item creation is
          // enabled, automatically switch to the free input field
          $scope.config.newItem = true;
        }
      });
    }
  }
};

/**
 * Build a default property name for the selected item based on
 * the single vs. multiple selection and the extracted mode @model or not
 *
 * @param $scope The scope to retrieve the configuration .multiple and .extract
 * @param singularPropertyName The singular form of the property name
 * @param singularExtractPropertyName The singular form of the extract property name
 * @returns {String} The default property name
 */
function defaultModelProperty($scope, singularPropertyName, singularExtractPropertyName) {
  if ($scope.extract == '@model') {
    return $scope.multiple ? inflection.pluralize(singularExtractPropertyName) : singularExtractPropertyName;
  } else {
    return $scope.multiple ? inflection.pluralize(singularPropertyName) : singularPropertyName;
  }
}
