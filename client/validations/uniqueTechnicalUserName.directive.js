angular.module('probedock.uniqueTechnicalUserNameValidation', [ 'probedock.api' ]).directive('uniqueTechnicalUserName', function(api, $q) {
  return {
    require: 'ngModel',
    link: function($scope, element, attrs, ctrl) {
      ctrl.$asyncValidators.uniqueUserName = function(modelValue) {

        // If the name is blank there can be no name conflict with another user.
        if (_.isBlank(modelValue)) {
          return $q.when();
        }

        var userId = $scope.user ? $scope.user.id : null;

        return api({
          url: '/users',
          params: {
            name: modelValue,
            organizationId: $scope.currentOrganization.id,
            technical: true,
            pageSize: 1
          }
        }).then(function(res) {
          // value is invalid if a matching user is found (length is 1)
          return $q[res.data.length && res.data[0].id != userId ? 'reject' : 'when']();
        }, function() {
          // consider value valid if uniqueness cannot be verified
          return $q.when();
        });
      };
    }
  };
});
