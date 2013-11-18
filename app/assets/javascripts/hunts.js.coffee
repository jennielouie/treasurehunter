# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

getHunts = ->
  #  Making the call to get all the hunts
  call = $.ajax('/hunts.json', {
      method: 'GET'
    })
  # After call is successful, the hunts are added to the hunt list on the index page
  call.done (data) ->
    _.each data, (h) ->
      $('.huntList ul').prepend("<li data-role='#{h.role}' data-id='#{h.id}'>
        <strong>Title</strong>: #{h.title}<br>
        <strong>Role</strong>: #{h.role}<br>
        <strong>Start</strong>: #{h.date}<br>
        <br>
        </li>")
    $('.huntList').prepend("<h3 style='letter-spacing: 10px'>Upcoming Hunts:</h3><br>")


getLeaders = (id) ->
  #Pulls name and progress data from hunts hash
  call = $.ajax("/hunts/#{id}", {
      method: 'GET'
    })

# After call is successful, the locations map is plotted
  call.done (data) ->

    thisHuntData = data
    # Setting up leaderboard
    # Sorting hunters by progress
    names = _.sortBy data.name, (p) ->
      -p.prog
    # Creating the list of hunters
    leaders = "<h3 style= 'letter-spacing: 10px; text-align: center'>Progress of Each Player (total of #{data.loc.length} Treasures)</h3><div class='leaderBoard'><ol>"
    _.each names, (d) ->
      leaders += "<li><p>#{d.name} is currently searching for Treasure #{d.prog}</p></li>"
    leaders += "</ol></div>"

    # role = "huntmaster"
    $('.huntMasterDisplay').prepend("#{leaders}")
    $('.huntMasterDisplay').removeClass('display')
    # makeLeaderMap(thisHuntData)


getLocations = (id) ->
# Populates the huntmasters hunt location view
  # thisHunt = $('.huntTabs').data('id')
  call = $.ajax("/hunts/#{id}", {
      method: 'GET'
    })

# After call is successful, the locations map is plotted
  call.done (data) ->

    thisHuntData = data
    role = "huntmaster"
    $('.huntMasterDisplay').prepend("<div class='map' id='huntMap'>Map</div>")
    $('.huntMasterDisplay').removeClass('display')
    makeMap(thisHuntData, role)

# Sets options for the position search
options = {
  enableHighAccuracy: true,
  timeout: 5000,
  maximumAge: 0
}


# Declaring the current coordinate variables
crd = {}
currentLat = 0
currentLong = 0
currentHint = ''
currentClues = ''
currentAnswer = ''
currentClue = ''
currentNumber = ''
status = false
checkLocation = ''
huntInfo = ''
count = 1
# Function for checking the hunters distance from the clue location
getDistance = (currentLat, currentLong, crd) ->
  R = 6371
  d = Math.acos(Math.sin(currentLat)*Math.sin(crd.latitude) + Math.cos(currentLat)*Math.cos(crd.latitude) * Math.cos(crd.longitude-currentLong)) * R

# On a successful position check the current coordinates are stored and if distance is within the bounds of the clue location a text is sent to the user. also status is set to true to prevent texts from continually being sent
success = (pos) ->
  crd = pos.coords
  console.log crd
  console.log('Your current position is:')
  console.log('Latitude : ' + crd.latitude)
  console.log('Longitude: ' + crd.longitude)
  console.log('More or less ' + crd.accuracy + ' meters.')
  console.log currentLat

  dist = getDistance(currentLat, currentLong, crd)
  console.log 'Distance: ' + dist
  console.log status
  myDate = new Date()
  finish = formatDate("#{huntInfo.end}")
  if myDate > finish
    clearInterval checkLocation
    body = "Sorry! Game time has expired and no one won. Thanks for playing!"
    _.each huntInfo.name, (d) ->
      if d.phone != currentNumber
        $.ajax("/send_texts/+1#{d.phone}/#{body}", {
          method: 'GET'
        })
    $('.answerDiv').empty()
    $('.huntDisplay').empty()
    $('.huntDisplay').append("<h3>#{body}</h3>")
    $.ajax("/hunt_users/#{huntInfo.id}", {
      method: 'PUT',
      data: {
        progress: {
          game_status: false
        }
      }
    })
  else
    if dist < 1 # 0.059144 # 100000

      if status == false
        form = JST['templates/answer_form']({})
        $('.answerDiv').append(form)
        textcall = $.ajax("/send_texts/+1#{currentNumber}/#{currentHint}", {
            method: 'GET'
          })


      status = true
    if $('.huntClues').hasClass('active')
      $('.answer').removeClass('display')
  count += 1
error = (err) ->
  console.warn('ERROR(' + err.code + '): ' + err.message)
# Checks the user's current position
getPosition = ->
  console.log 'inside getPosition'
  navigator.geolocation.getCurrentPosition(success, error, options)


# Storing the location coordinates for the current clue location, as well as its associated clues
clueLocation = (data, prog) ->
  _.find data.loc, (l) ->
    if l.order == prog
      currentLat = l.lat
      currentLong = l.long
      currentClues = l

# Storing the current clue, hint, and answer
getCluesInfo = (current) ->
  _.each current, (c) ->
    if c.answer != 'null'
      currentAnswer = c.answer
      currentClue = c.question
    else
      currentHint = c.question

# Creating a participant list
createParticipant = (data) ->
  if data.name.length > 0
    entry = "<ul>"
    _.each data.name, (d) ->
      entry += "<li><p>#{d.name}</p></li>"
    entry += "</ul>"
    return entry
  else
    return 'None'

formatDate = (date) ->
  s = date
  a = s.split(/[^0-9]/)

  d = new Date(a[0],a[1]-1,a[2],a[3])



$ ->
  # Populating the index page with user-specific hunts
  getHunts()
  console.log 'Running get position'
  getPosition()


  # When hunt is clicked it will display the proper view based on the user's role (hunter or huntmaster)
  # NOTE 'display' actually means 'hide'
  $('.huntList').on 'click', 'li', ->
    $('.indexView').addClass('display')
    hunt_id = $(this).data('id')
    if $(this).data('role') == 'hunter'
      $('.huntMasterView').addClass('display')
      $('.huntDetails').addClass('active')
      $('.huntView').removeClass('display')
      $('.huntTabs').data('id', hunt_id)
      $.get("/hunts/#{hunt_id}").done (data) ->
        myDate = new Date()
        huntDate = formatDate("#{data.date}")

        currentNumber = data.current.phone
        prog = parseInt(data.current.progress)
        huntInfo = data
        clueLocation(data, prog)
        getCluesInfo(currentClues.clues)
        console.log game_status
        if huntDate < myDate && data.current.progress >= 1 && data.current.game_status

          # Checking the user's current location
          # Setting a timer to check the positon every 15 secs
          checkLocation = setInterval getPosition, 5000

        newEntry = JST['templates/hunt_master_display']({ data: data, clue: huntInfo.loc.length })
        $('.huntDisplay').prepend(newEntry)
        # Adding participant list
        $('.part').append(createParticipant(huntInfo))
        myDate = new Date()
        huntDate = formatDate("#{data.date}")



        if huntDate < myDate && "#{data.current.progress}" < 1
          $('.huntDisplay').prepend('<button class="start">Start</button>')

        $('.start').click ->
          call = $.ajax("/hunt_users/#{huntInfo.id}", {
              method: 'PUT',
              data: {
                progress: {
                    progress: '1'
                  }
              }
            })
          call.done (start_data) ->
            prog = 1
            clueLocation(huntInfo, prog)
            # Setting a timer to check the positon every 15 secs
            checkLocation = setInterval getPosition, 5000
          $(this).remove()
    else
      $('.huntView').addClass('display')
      $('.huntMasterView').removeClass('display')
      $('.huntMasterDetails').addClass('active')
      $('.huntMasterTabs').data('id', hunt_id)
      # Make the ajax call to get the hunt information
      # Display the hunt information after the ajax call is successful`
      $.get("/hunts/#{hunt_id}").done (data) ->
        myDate = new Date()
        huntDate = formatDate("#{data.date}")
        console.log data
        currentNumber = data.current.phone

        # Creating hunt details list and displaying it
        newEntry = JST['templates/hunt_master_display']({ data: data, clue: data.loc.length })
        $('.huntMasterDisplay').prepend(newEntry)
        # Adding participant list
        $('.part').append(createParticipant(data))

  # When "Add hunt" button is clicked it will display the huntmaster view (hunt details and locations)
  $('.addHunt').click ->
    $('.indexView').addClass('display')
    $('.huntMasterView').removeClass('display')
    $('.huntMasterTabs').removeData('id')
    $('.huntMasterDisplay').empty()
    entry = JST['templates/new_hunt']({})
    $('.huntMasterDisplay').prepend(entry)
    allUsers = []
    currentUsername = ''
    $.ajax('/users', {
        method: 'GET'
      }).done (data) ->
        allUsers = data
        _.each allUsers, (u) ->
          if u.current
            currentUsername = u.username


    # when button is clicked display the form to add participants
    $('.add_participants').click ->
      event.preventDefault()
      $(this).hide()
      entry = JST['templates/add_participants']({})
      $('.hunter_list').prepend(entry)


      # populate the hunter_list in the create form
      $('.addParticipants').click ->
        event.preventDefault()
        # Grab the form value
        $('.errors').empty()
        newPlayer = $('#participant_form').val()
        us = false
        cu = ''

        _.each allUsers, (u) ->
          if newPlayer == u.username

            us = true
          if newPlayer == currentUsername
            cu = 'currentUser'
        if us == false
          $('.errors').append('<p>Not a valid user. Please try a new name.</p>')
          return
        else if cu == 'currentUser'
          $('.errors').append("<p>You can't join your own hunt. Please try a new name.</p>")
          return
        else
          $('.errors').empty()
          # Add name to the list
          $('.hunter_list').append("<li><p>#{newPlayer}</p></li>")
          # Clear the form value
          $('#participant_form').val('')
      # When done, the add participant form is removed and the add participant button is revealed
      $('.done').click ->
        event.preventDefault()
        $('.errors').remove()
        $('#participants').remove()
        $('.add_participants').show()

    $('.createHunt').submit ->
      event.preventDefault()
      title = $('#huntTitle').val()
      start_location = $('#startLocation').val()
      start_time = $('#startTime').val()
      start_date = $('#startDate').val()
      end_time = $('#endTime').val()
      end_date = $('#endDate').val()
      description = $('#huntDescription').val()
      players = $('.hunter_list li')
      prize = $('#huntPrize').val()




      # Creating an object to pass into the create hunt ajax call
      hunt = {
        title: title,
        description: description,
        prize: prize,
        start_location: start_location,
        date: start_date + ' ' + start_time
        end: end_date + ' ' + end_time
      }
      if hunt.title == '' || hunt.description == '' || hunt.date == '' || hunt.start_location == '' || hunt.end == ''
        $('.incomplete').remove()
        $('.huntMasterDisplay').prepend('<p class="incomplete">Sorry, all fields need to be filled out. Please try again!</p>')
        return

      # Ajax call to save the hunt
      call = $.ajax('/hunts', {
          method: 'POST',
          data: {
            hunt: hunt
          }
        })

      call.done (data) ->
        _.each players, (p) ->
          # Ajax call to get the user id that corresponds to the partipants username
          userCall = $.ajax("/user/#{p.textContent}", {
              method: 'GET',
            })
          # After a successful call, use this user id and the hunt id to save to huntUser db
          userCall.done (user) ->
            if user == null
              alert "Your hunt has been saved, but #{p.textContent} is not a user and cannot be added."
            # Creating object with participant info
            hunt_user = {
                    hunt_id: data.id,
                    user_id: user.id,
                    progress: '0',
                    role: 'hunter'
                  }
            # Making an ajax call to save participant entries to the db
            huntUserCall = $.ajax("/hunt_users/#{user.id}/confirm", {
                method: 'POST'
                data: {
                  hunt_user: hunt_user
                }
              })
        # Creating an object with current user info
        creater = {
              hunt_id: data.id,
              user_id: data.current_user,
              role: 'huntmaster'
            }
        # Ajax call to save the current user as huntmaster in the hunt user db
        createrCall = $.ajax('/hunt_users', {
            method: 'POST',
            data: {
                hunt_user: creater
              }
          })
        # Removing the create hunt form
        $('.createHunt').remove()
        $('.incomplete').remove()
        # Creating hunt details list and displaying it
        newEntry = JST['templates/hunt_master_display']({ data: data, clue: 0 })
        $('.huntMasterDisplay').prepend(newEntry)
        # Adding participant list
        $('.part').append("<li>None</li>")
        # Adding the newly created hunt_id to the huntmasterTab for referencing
        hunt_id = data.id
        $('.huntMasterTabs').data('id', hunt_id)
        # Add new hunt to the hunts list on the index page
        entry = JST['templates/newly_created_hunt']({ data: data })
        $('.huntList ul').prepend(entry)

  # When "back" button is pressed, the index page is displayed.  NOTE 'display' actually means 'hide'
  $('.goBack').click ->
    if !($('.huntMasterView').hasClass('display'))
      $('.huntMasterView').addClass('display')
    if !($('.huntView').hasClass('display'))
      $('.huntView').addClass('display')
    if !($('.mapView').hasClass('display'))
      $('.mapView').addClass('display')
    if !($('.mapDisplay').hasClass('display'))
      $('.mapDisplay').addClass('display')
    if !($('.answerDiv').hasClass('display'))
      $('.answerDiv').addClass('display')
    $('.answer').remove()
    $('.huntNav').removeClass('active')
    $('.huntMasterNav').removeClass('active')
    $('.indexView').removeClass('display')
    $('.huntMasterDisplay').empty()
    $('.huntDisplay').empty()
    $('#coordinates ul').empty()
    $('.errors').empty()
    status = false
    clearInterval(checkLocation)

  #**** Huntmaster View ****
  #display hunt info
  $('.huntMasterTabs').on 'click', '.huntMasterNav', ->


    $('.huntMasterDetails').addClass('active')
    # grab the current tab to use in the callback
    currentTab = $(this)
    # clear the tab of previous data
    $('.huntMasterDisplay').empty()
    $('.mapView').addClass('display')
    $('#coordinates ul').empty()
    $('.errors').empty()
    # if Hunt Details tab is clicked, show the Create Hunt form or the hunt details
    if currentTab.hasClass('huntMasterDetails')


      # If starting a new hunt, a create form will be displayed
      if !($('.huntMasterTabs').data('id'))
        $(this).addClass('active')
        entry = JST['templates/new_hunt']({})
        $('.huntMasterDisplay').prepend(entry)

        # when button is clicked display the form to add participants
        $('.add_participants').click ->
          event.preventDefault()
          $(this).hide()
          entry = JST['templates/add_participants']({})
          $('.hunter_list').prepend(entry)

          # populate the hunter_list in the create form
          $('.addParticipants').click ->
            event.preventDefault()
            # Grab the form value
            name = $('#participant_form').val()
            # Add name to the list
            $('.hunter_list').append("<li><p>#{name}</p></li>")
            # Clear the form value
            $('#participant_form').val('')
          # When done, the add participant form is removed and the add participant button is revealed
          $('.done').click ->
            event.preventDefault()
            $('#participants').remove()
            $('.add_participants').show()

        $('.createHunt').submit ->
          event.preventDefault()
          title = $('#huntTitle').val()
          start_location = $('#startLocation').val()
          start_time = $('#startTime').val()
          start_date = $('#startDate').val()
          end_time = $('#endTime').val()
          end_date = $('#endDate').val()
          description = $('#huntDescription').val()
          prize = $('#huntPrize').val()
          players = $('.hunter_list li')
          if hunt.title == '' || hunt.description == '' || hunt.date == '' || hunt.start_location == '' || hunt.end == ''
            $('.incomplete').remove()
            $('.huntMasterDisplay').prepend('<p class="incomplete">Sorry, all fields need to be filled out. Please try again!</p>')
            return

          # Creating an object to pass into the create hunt ajax call
          hunt = {
            title: title,
            description: description,
            prize: prize,
            start_location: start_location,
            date: start_date + ' ' + start_time
            end: end_date + ' ' + end_time
          }
          # Ajax call to save the hunt
          call = $.ajax('/hunts', {
              method: 'POST',
              data: {
                hunt: hunt
              }
            })

          call.done (data) ->
            console.log data
            _.each players, (p) ->
              # Ajax call to get the user id that corresponds to the partipants username
              userCall = $.ajax("/user/#{p.textContent}", {
                  method: 'GET',
                })
              # After a successful call, use this user id and the hunt id to save to huntUser db
              userCall.done (user) ->
                if user == null
                  alert "Your hunt has been saved, but #{p.textContent} is not a user and cannot be added."
                # Creating object with participant info
                hunt_user = {
                        hunt_id: data.id,
                        user_id: user.id,
                        progress: '0',
                        role: 'hunter'
                      }
                # Making an ajax call to save participant entries to the db
                huntUserCall = $.ajax("/hunt_users/#{user.id}/confirm", {
                    method: 'POST'
                    data: {
                      hunt_user: hunt_user
                    }
                  })
            # Creating an object with current user info
            creater = {
                  hunt_id: data.id,
                  user_id: data.current_user,
                  role: 'huntmaster'
                }
            # Ajax call to save the current user as huntmaster in the hunt user db
            createrCall = $.ajax('/hunt_users', {
                method: 'POST',
                data: {
                    hunt_user: creater
                  }
              })
            # Removing the create hunt form
            $('.createHunt').remove()
            $('.incomplete').remove()
            # Creating hunt details list and displaying it
            newEntry = JST['templates/hunt_master_display']({ data: data, clue: 0 })
            $('.huntMasterDisplay').prepend(newEntry)
            # Adding participant list
            $('.part').append(createParticipant(data))
            # Adding the newly created hunt_id to the huntmasterTab for referencing
            hunt_id = data.id
            $('.huntMasterTabs').data('id', hunt_id)
            # Add new hunt to the hunts list on the index page
            entry = JST['templates/newly_created_hunt']({ data: data })
            $('.huntList ul').prepend(entry)
      # If there is a current hunt id
      else
        $('.huntMasterNav').removeClass('active')
        $(this).addClass('active')
        # Grabbing the current hunt id
        id = $('.huntMasterTabs').data('id')
        # Do an ajax call to get the hunt details
        call = $.ajax("/hunts/#{id}", {
            method: 'GET'
          })
        # After the ajax call is complete, appending the details to huntMasterDisplay tab
        call.done (data) ->
          # Creating hunt details list and displaying it
          newEntry = JST['templates/hunt_master_display']({ data: data, clue: data.loc.length })
          $('.huntMasterDisplay').prepend(newEntry)
          # Adding participant list
          $('.part').append(createParticipant(data))

    # If add locations is clicked, the map or an alert will show
    else if currentTab.hasClass('huntMasterClues')
      $('.huntMasterNav').removeClass('active')
      $(this).addClass('active')
      # If there is an current hunt id
      if $('.huntMasterTabs').data('id')
        $('.mapView').removeClass('display')
        initialize()
      # If there isnt a hunt id
      else
        $('.huntMasterDisplay').append('<h3>Sorry! You need to save a hunt before you can add locations.</h3>')
    # If hunt locations is clicked
    else if currentTab.hasClass('huntMasterLocations')
      $('.huntMasterNav').removeClass('active')
      $(this).addClass('active')
      if $('.huntMasterTabs').data('id')
        $('.huntMasterDisplay').empty()
        if !($('.mapView').hasClass('display'))
          $('.mapView').addClass('display')
        id = $('.huntMasterTabs').data('id')
        getLocations(id)
      else
        $('.huntMasterDisplay').append('<h3>Sorry! You need to save a hunt before you can add locations.</h3>')
    else #if currentTab.hasClass('huntMasterLocations')
      $('.huntMasterNav').removeClass('active')
      $(this).addClass('active')
      if $('.huntMasterTabs').data('id')
        $('.huntMasterDisplay').empty()
        if !($('.leaderView').hasClass('display'))
          $('.leaderView').addClass('display')
        id = $('.huntMasterTabs').data('id')
        getLeaders(id)


  # Adding a location to a hunt
  $('.addLocation').submit ->
    event.preventDefault()
    # Grabbing the form values
    lat = $('#location_lat').val()
    long = $('#location_long').val()
    name = $('#location_name').val()
    question = $('#clueQuestion').val()
    answer = $('#clueAnswer').val()
    hint = $('#clueHint').val()
    # if all the felds arent filled in, an error is flashed
    if !(lat && long && name && question && answer && hint)
      $('#coordinates ul').empty()
      $('#coordinates ul').prepend("<p>Sorry! Need more info!</p>")
      return
    # Grabbing the current hunt id
    id = $('.huntMasterTabs').data('id')
    # Stores the number of locations
    nextLoc = ''
    # Ajax call to find the number of locations associated with the current hunt
    call = $.ajax("/locations/#{id}", {
        method: 'GET'
      })

    # After a successful it sets the nextLoc data equal to the next location number
    call.done (data) ->
      nextLoc = data.length + 1
      # Ajax call to save the location to the location db

      locationCall = $.ajax('/locations', {
          type: 'POST'
          data: {
            location: {
              lat: lat
              long: long
              name: name
            }
          }
        })

      # After a successful save, the id of the location is sent back
      locationCall.done (loc_data) ->
        # Hunt info object is created
        hunt_loc = {hunt_id: id, location_id: loc_data.id , loc_order: nextLoc}

        # Ajax call is made to save the hunt_id, loc_id, and loc_order to the huntLocation db
        huntLocCall = $.ajax("/hunt_locations", {
            type: 'POST',
            data: {
              hunt_loc: hunt_loc
            }
          })

        huntLocCall.done (hunt_loc_data) ->

        # Creating the clue info object
        clueInfo = {question: question, location_id: loc_data.id, answer: answer}
        # Ajax call is made to save the clue and answer to the db
        clueCall = $.ajax('/clues', {
            method: 'POST',
            data: {
              clue: clueInfo
            }
          })

        clueCall.done (clue_data) ->
        # Ajax call is made to save the hint to the db, with a null placeholder for the answer
        hintInfo = {question: question, location_id: loc_data.id, answer: 'null'}

        clueCall = $.ajax('/clues', {
            method: 'POST',
            data: {
              clue: hintInfo
            }
          })
        # Notifing the huntmaster that the clue was saved
        clueCall.done (clue_data) ->
          $('#coordinates ul').empty()
          $('#coordinates ul').prepend("<p>Location: #{loc_data.name} was saved successfully!</p>")
    # Clearing the form values
    $('#location_lat').val('')
    $('#location_long').val('')
    $('#location_name').val('')
    $('#clueQuestion').val('')
    $('#clueAnswer').val('')
    $('#clueHint').val('')






  # Displaying the hunter view information
  $('.huntTabs').on 'click', '.huntNav', ->

    $('.huntDetails').addClass('active')
    # Grab the current tab to use in the callback function
    currentTab = $(this)
    if !($('.answer').hasClass('display'))
      $('.answer').addClass('display')

    # Grab the id of the hunt for the ajax call
    id = $(this).parent().data('id')

    # Make the ajax call to get the hunt information
    # Display the hunt information after the ajax call is successful
    $.get("/hunts/#{id}").done (data) ->
      myDate = new Date()
      huntDate = formatDate("#{data.date}")

      # Clear out any information that the hunt display is showing, so the new info can be shown
      $('.huntDisplay').empty()
      if !($('.mapDisplay').hasClass('display'))
        $('.mapDisplay').addClass('display')
      # Setting up the participant names as a list
      entry = createParticipant(data)

      # Setting up leaderboard
      # Sorting hunters by progress
      names = _.sortBy data.name, (p) ->
        -p.prog
      # Creating the list of hunters
      leaders = "<h3 style= 'letter-spacing: 10px; text-align: center'>Progress of Each Player (total of #{data.loc.length} Treasures):</h3><div class='leaderBoard'><ul>"
      _.each names, (d) ->
        leaders += "<li><p>#{d.name} is on Treasure #{d.prog}</p></li>"
      leaders += "</ul></div>"

      # Displaying the correct information based on which tab is currently active
      if currentTab.hasClass('huntDetails')
        $('.huntNav').removeClass('active')
        currentTab.addClass('active')
        newEntry = JST['templates/hunt_master_display']({ data: data, clue: data.loc.length })
        $('.huntDisplay').prepend(newEntry)
        # Adding participant list
        $('.part').append(entry)
        myDate = new Date()
        huntDate = formatDate("#{data.date}")
        if huntDate < myDate && "#{data.current.progress}" < 1
          $('.huntDisplay').prepend('<button class="start">Start</button>')

        $('.start').click ->
          call = $.ajax("/hunt_users/#{id}", {
              method: 'PUT',
              data: {
                progress: '1'
              }
            })
          call.done (start_data) ->
            prog = 1
            clueLocation(huntInfo, prog)
            # Setting a timer to check the positon every 15 secs
            checkLocation = setInterval getPosition, 5000
          $(this).remove()


      else if currentTab.hasClass('huntClues')
        $('.huntNav').removeClass('active')
        currentTab.addClass('active')
        $('.answerDiv').removeClass('display')
        # Setting the current clue, answer, and hint based on the current hunters progress
        prog = parseInt(data.current.progress)

        clueLocation(data, prog)

        getCluesInfo(currentClues.clues)


        # Displaying the current clue
        $('.huntDisplay').prepend("<h4>Clue #{data.current.progress} of #{data.loc.length}</h4><br>
          <p>#{currentClue}</p><br>")
        $('.answer').removeClass('display')
        # When answer is submitted, checking to see if hunter is correct
        $('.answerDiv').on 'submit', '.answer',  ->
          event.preventDefault()
          ans = $('#answer').val().toLowerCase()
          console.log ans
          console.log currentAnswer.toLowerCase()

          # if ans = the correct answer, progress needs to be updated to the db and the next clue needs to be revealed
          if ans == currentAnswer.toLowerCase()
            # If its the last location, the player wins, and it clear the check location function interval and text the hunters that someone won
            if prog == data.loc.length
              clearInterval(checkLocation)
              body = "Hooray! Congratulations to #{data.current.name} for winning the game! Thanks everyone for playing!"
              _.each data.name, (d) ->
                if d.phone != currentNumber
                  textcall = $.ajax("/send_texts/+1#{d.phone}/#{body}", {
                    method: 'GET'
                  })
              $('.answer').addClass('display')
              $('.huntDisplay').empty()
              $('.huntDisplay').append("<h3>Conratulations, #{data.current.name}, you have won!!</h3>")
              console.log 'Im activated'
              $.ajax("/hunt_users/#{id}", {
                method: 'PUT',
                data: {
                  progress: {
                    game_status: false
                  }
                }
              })
            # If not the last location, then the users progress is saved
            else
              prog += 1
              call = $.ajax("/hunt_users/#{id}", {
                method: 'PUT',
                data: {
                  progress: {
                    progress: "#{prog}"
                  }
                }
              })
              # Updating the next clue location
              clueLocation(data, prog)
              # Updating the current clue, hint and answer
              getCluesInfo(currentClues.clues)
              # Reset satus, so player will recieve texts for the next location
              status = false
              # Displaying the proper clue
              $('.wrong').remove()
              $('.huntDisplay h4').text("Clue #{prog} of #{data.loc.length}")
              $('.huntDisplay p').text("#{currentClue}")
              $('.answerDiv').empty()
          else
            $('.answer').val('')
            $('.wrong').remove()
            $('.huntDisplay').append('<p class="wrong">Sorry! Your answer is incorrect!</p>')


      else if currentTab.hasClass('huntMap')
        $('.huntNav').removeClass('active')
        currentTab.addClass('active')
        $('.huntDisplay').removeClass('display')
        $('.huntDisplay').prepend("<div class='map' id='huntMap'>Map</div>")
        #  Making the call to get all the locations for the specific hunt id
        thisHunt = $('.huntTabs').data('id')
        prog = parseInt(data.current.progress)
        call = $.ajax("/hunts/#{thisHunt}", {
          method: 'GET'
        })
      # After call is successful, the locations map is plotted
        call.done (data) ->
          thisHuntData = data
          role = "hunter"
          prog = prog
          makeMap(thisHuntData, role, prog)
          $('.huntDisplay').removeClass('display')
      else
        $('.huntNav').removeClass('active')
        currentTab.addClass('active')
        $('.huntDisplay').prepend("#{leaders}")














