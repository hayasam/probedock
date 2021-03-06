angular.module('probedock.testContributionsWidget').directive('testContributionsWidget', function() {
  return {
    restrict: 'E',
    controller: 'TestContributionsCtrl',
    templateUrl: '/templates/widgets/test-contributions/contributions.template.html',
    scope: {
      organization: '=',
      project: '='
    }
  };
}).controller('TestContributionsCtrl', function(api, $scope) {

  $scope.$watch('organization', function(organization) {
    if (organization) {
      fetchContributions();
    }
  });

  $scope.$watch('project', function(project) {
    if (project) {
      fetchContributions();
    }
  });

  function fetchContributions() {

    var params = {};

    if ($scope.organization) {
      params.organizationId = $scope.organization.id;
    }

    if ($scope.project) {
      params.projectId = $scope.project.id;
    }

    api({
      url: '/metrics/contributions',
      params: _.extend(params, {
        withUser: 1
      })
    }).then(function(res) {
      $scope.contributions = res.data;
    });
  }
});
