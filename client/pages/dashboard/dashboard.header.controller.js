angular.module('probedock.dashboardPage').controller('DashboardHeaderCtrl', function(orgEditModal, $scope, $state, $stateParams) {

  var modal;
  $scope.currentState = $state.current.name;

  $scope.$on('$stateChangeSuccess', function(event, toState) {

    $scope.currentState = toState.name;

    if (toState.name == 'org.dashboard.default.edit') {
      modal = orgEditModal.open($scope);

      modal.result.then(function() {
        $state.go('^', {}, { inherit: true });
      }, function(reason) {
        if (reason != 'stateChange') {
          $state.go('^', {}, { inherit: true });
        }
      });
    }
  });
});