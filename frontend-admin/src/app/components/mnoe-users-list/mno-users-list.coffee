#
# Mnoe Users List
#
@App.directive('mnoeUsersList', ($filter) ->
  restrict: 'E'
  scope: {
    list: '='
  },
  templateUrl: 'app/components/mnoe-users-list/mno-users-list.html',
  link: (scope) ->

    # Variables initialization
    scope.users =
      displayList: []
      widgetTitle: 'Last 10 users'
      search: ''

    setLastUsersList = () ->
      scope.users.widgetTitle = 'Last 10 users'
      scope.users.displayList = $filter('orderBy')(scope.list, '-created_at')
      scope.users.displayList = $filter('limitTo')(scope.users.displayList, 10)

    setSearchUsersList = () ->
      scope.users.widgetTitle = 'Search result'
      searchToLowerCase = scope.users.search.toLowerCase()
      scope.users.displayList = _.filter(scope.list, (user) ->
        email = _.startsWith(user.email.toLowerCase(), searchToLowerCase)
        name = _.startsWith(user.name.toLowerCase(), searchToLowerCase)
        surname = _.startsWith(user.surname.toLowerCase(), searchToLowerCase)
        (email || name || surname)
      )
      scope.users.displayList = $filter('orderBy')(scope.users.displayList, 'email')

    scope.searchChange = () ->
      if scope.users.search == ''
        setLastUsersList()
      else
        setSearchUsersList()

    scope.$watch('list', (newVals, oldVals) ->
      setLastUsersList()
    , true)
)
