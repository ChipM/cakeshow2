{PagedListView} = require('./paged_views')

RegistrantViews = require('./registrant_views')

entryTemplate = require('./templates/entry')
entryListTemplate = require('./templates/entry_list')

signupTemplate = require('./templates/signup')
registrantSignupTemplate = require('./templates/registrant_signup')
registrantSignupListTemplate = require('./templates/registrant_signup_list')

exports.EntryView = class EntryView extends Backbone.View
  tagName: 'tr'
  className: 'entry'
  
  events:
    'click input.didBring': 'didBringClicked'
    'click input.styleChange': 'categoryChangeClicked'
    'change select.category': 'categoryChanged'
    'keydown input.entryNumber': 'entryNumberKeyPressed'
    'change input.entryNumber': 'syncEntryNumber'
  
  initialize: =>
    this.categories = this.model.getCategories()
    this.badEntryNumber = false
  
  render: =>
    renderParams = this.model.toJSON()
    renderParams.categories = this.categories
    this.$el.html(entryTemplate.render(renderParams))
    selectedIndex = _.indexOf(this.categories, this.model.categoryName())
    this.$el.find('select.category')[0].selectedIndex = selectedIndex
    return this
  
  didBringClicked: =>
    this.model.set('didBring', this.$el.find('.didBring')[0].checked)
    this.model.save()
  
  categoryChangeClicked: =>
    this.model.set('styleChange', this.$el.find('.styleChange')[0].checked)
    this.model.save()
  
  categoryChanged: =>
    selected = this.$el.find('select.category')[0].selectedIndex
    this.model.setCategoryName(this.categories[selected])
    this.model.set('styleChange', true)
    this.$el.find('input.styleChange')[0].checked = true
    this.model.save()
  
  clearEntryNumberTimer: =>
    if this.entryNumTimer?
      window.clearTimeout(this.entryNumTimer)
    this.entryNumTimer = null
    this.$el.find('div.sync-icon').css('visibility', 'hidden')
      
  restartEntryNumberTimer: =>
    this.clearEntryNumberTimer()
    this.entryNumTimer = window.setTimeout(this.syncEntryNumber, 5000)
    this.$el.find('div.sync-icon').css('visibility', 'visible')
  
  syncEntryNumber: =>  
    numInput = this.$el.find('input.entryNumber')[0]
    if numInput.value != ''
      entryNumber = parseInt(numInput.value, 10)
      if isNaN(entryNumber)
        this.badEntryNumber = true
        this.$el.parents('.entries').find('.error-widget').show('blind')
      else
        if this.badEntryNumber
          this.$el.parents('.entries').find('.error-widget').hide('blind')
        this.badEntryNumber = false
        this.model.set('entryNumber', entryNumber)
        this.model.save()
    this.clearEntryNumberTimer()
  
  entryNumberKeyPressed: =>
    this.restartEntryNumberTimer()

exports.EntryListView = class EntryListView extends Backbone.View
  className: 'entry-list'
  
  initialize: ->
    this.collection.bind('reset', this.render)
    this.collection.bind('add', this.add)
    this.collection.view = this
  
  add: (entry) =>
    view = new EntryView(model: entry)
    this.$el.find('table').append(view.render().el)
    
  render: =>
    this.$el.html(entryListTemplate.render())
    this.add(entry) for entry in this.collection.models
    
    return this

exports.SignupView = class SignupView extends Backbone.View
  className: 'signup'
  
  render: =>
    this.$el.html(signupTemplate.render(this.model.toJSON()))
    this.$el.find('.accordion').accordion(
      collapsible: true
      active: false
      autoHeight: false
      changestart: this.toggleEvents
    )
    return this
  
  toggleEvents: =>
    unless this.entriesView?
      this.entriesView = new EntryListView(collection: this.model.getEntries())
      this.entriesView.collection.fetch()
      this.$el.find('.entries').append(this.entriesView.render().el)

exports.RegistrantSignupView = class RegistrantSignupView extends Backbone.View
  className: 'registrantSignup'
    
  initialize: =>
    this.model.bind('change', this.render)
  
  render: =>
    this.$el.html(registrantSignupTemplate.render())
    signupView = new SignupView(tagName: 'div', model: this.model.signup)
    registrantView = new RegistrantViews.RegistrantView(tagName: 'div', model: this.model.registrant)
    
    this.$el.find('.signup').append(signupView.render().el)
    this.$el.find('.registrant').append(registrantView.render().el)
    
    return this
  
exports.RegistrantSignupListView = class RegistrantSignupListView extends PagedListView
  el: '#content'
  
  initialize: =>
    this.register('registrant-signups')
    this.collection.bind('reset', this.render)
    this.collection.bind('add', this.add)
    this.collection.view = this
  
  add: (registrantSignup) =>
    view = new RegistrantSignupView( {tagName: 'li', model: registrantSignup} )
    this.$el.find('#registrant-signups').append(view.render().el)
    
  render: =>
    $('div.search-fields input').autocomplete(
      minLength: 2
      source: this.searchSuggestions
      select: this.searchSelected
    )
    this.$el.html(registrantSignupListTemplate.render())
    
    this.add(registrantSignup) for registrantSignup in this.collection.models
    
    super()
    return this
  
  searchSuggestions: (request, callback) =>
    this.collection.search(request.term, (results) ->
      for result in results
        result.value = result.registrant.firstname + " " + result.registrant.lastname
      
      callback(results)
    )
  
  searchSelected: (event, ui) =>
    app.router.navigate('/signups/' + ui.item.signup.id, trigger: true)
    