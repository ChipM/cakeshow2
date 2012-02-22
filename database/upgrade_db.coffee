mysql = require("mysql")
Sequelize = require('sequelize')

exit = (message) ->
  console.log(message)
  process.exit(1)

styleMap = 
  showcasecakes: "showcase"
  style1: "style1"
  style2: "style2"
  style3: "style3"
  style4: "style4"
  style5: "style5"
  style6: "style6"
  style7: "style7"
  special1: "special1"
  special2: "special2"
  special3: "special3"
  special4: "special4"
  special5: "special5"
  cupcakesentries: "cupcakes"


signupMap =
  registrationTime: "registration"
  RegistrantId: "registrantid"

class Upgrader
  cakeshowDBs : 
    "1": "2011"
    "09": "2009"
    "10": "2010"
    "12": "2012"
  
  upgrade : (cakeshowDB, onSuccess= ->) =>
    this.cakeshowDB = cakeshowDB
    
    this.upgradeRegistrants( =>
      showsToUpgrade = Object.keys(this.cakeshowDBs).length
      completed = 0
      for showNumber of this.cakeshowDBs
        this.upgradeCakeshow(showNumber, ->
          completed++
          if completed == showsToUpgrade
            onSuccess()
        )
    )
  
  upgradeRegistrants : (onSuccess= ->) =>
    this.registrantsDB = new mysql.createClient(
      hostname: "localhost"
      user: "root"
      password: ""
      database: "capitalc_registrants"
    )
    
    this.registrantsDB.query(
      'SELECT *' +
      'FROM registrants;',
      (error,rows,columns) =>
        if error
          exit("Error: " + error)
        
        completed = 0
        
        for row in rows
          newRow = {}
          for col of this.cakeshowDB.Registrant.rawAttributes when row[col]?
            newRow[col] = row[col]
          
          registrant = this.cakeshowDB.Registrant.build(newRow)
          registrant.save()
            .error( (error) ->
              console.log('Error inserting registrant: ' + error)
            )
            .success( =>
              completed++
              if completed == rows.length
                this.registrantsDB.end()
                onSuccess()
            )
    )

  upgradeCakeshow : (number, onSuccess= ->) =>
    dbName = "capitalc_cakeshow" + number
    this[dbName] = new mysql.createClient(
      hostname: "localhost"
      user: "root"
      password: ""
      database: dbName
    )
    
    signupUpgrader = new SignupUpgrader(this, this.cakeshowDBs[number])
    
    signups = this[dbName].query(
      "SELECT *" +
      "FROM contestantsignups;",
      (error, rows, columns) =>
        completed = 0
        for row in rows
          signupUpgrader.insertRegistrant(row, =>
            completed++
            if completed == rows.length
              this[dbName].end()
              onSuccess()
          )
    )

class SignupUpgrader
  constructor: (upgrader, year) ->
    this.upgrader = upgrader
    this.year = year
    this.cakeshowDB = upgrader.cakeshowDB

  insertRegistrant : (row, onSuccess= ->) =>
    signup = this.cakeshowDB.Signup.build(this.mapSignup(row, this.year))
    signup.save().success( =>
      this.insertRegistrantEntries(signup, row, onSuccess)
    )
  
  insertRegistrantEntries : (signup, oldRegistrant, onSuccess= ->) =>
    entryChain = new Sequelize.Utils.QueryChainer
    entries = []
    
    for style, entryStyle of styleMap when oldRegistrant[style]? and oldRegistrant[style] != ''
      count = oldRegistrant[style] ? 0
      if count > 0
        for i in [0..count-1]
          entry = this.cakeshowDB.Entry.build(
            year: this.year
            category: entryStyle
            didBring: false
            styleChange: false
          )
          entryChain.add(entry.save())
          entries.push(entry)
    
    entryChain.run()
      .error( (errors) ->
          console.log("Error inserting entries: " + errors)
      )
      .success( ->
        signup.setEntries(entries)
          .error( (error) ->
            console.log("Error linking entries to signup: " + error)
          )
          .success( ->
            onSuccess()
        )
    )
  
  mapSignup: (row, year) =>
    newRow = {}
    for newCol, colInfo of this.cakeshowDB.Signup.rawAttributes when newCol != 'id'
      oldCol = signupMap[newCol] ? newCol
  
      if row[oldCol]?
        type = colInfo.type ? colInfo
        
        converted = row[oldCol]
        
        switch type
          when Sequelize.BOOLEAN 
            if converted == "yes"
              converted = true
            else
              converted = false
          when Sequelize.INTEGER
            if typeof converted == "string"
              if converted == ""
                converted = 0
              else
                converted = parseInt(converted,10)     
        
        newRow[newCol] = converted
  
    newRow.year = year
    
    return newRow

module.exports = new Upgrader()