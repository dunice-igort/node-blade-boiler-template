mongoose = require('mongoose')
Schema = mongoose.Schema


fOCSchema = (settings)->
  ret = new Schema settings
  console.log("TYPING"+typeof ret)
  ret.statics.findOrCreate = (query,to_save, next)->
    that = this
    this.findOne query, (err, doc) ->
      if err
        err.flight_mes = "r"
        process.nextTick ()->
          next(err null)
      if doc
        err = {flight_mes:"d"}
        process.nextTick ()->
          next(err, doc)
      else
        if(to_save == null)
          to_save = query
        doc = new that to_save
        doc.save (err, doc) ->
          if err
            err.flight_mes = "r"
            process.nextTick ()->
              next(err, null)
          else
            process.nextTick ()->
              next(null, doc)
  ret.statics.mergeOrCreate = (query,to_save, next)->
    that = this
    this.findOne query, (err, doc) ->
      if err
        err.flight_mes = "r"
        process.nextTick ()->
          next(err,null)
      if doc
        `
        for(var k in settings){
          if(typeof settings[k] == "array"){
            var dc = 0;
            for(k2 in to_save[k]){
              var tempbool = true;
              for(var i=0;i<dc;i++)
                if(doc[k][i] == to_save[k][k2]){
                  tempbool = false;
                  break;
                }
              if(tempbool)
                doc[k].push(to_save[k][k2]);
            }
            continue;
          }
          if(!to_save[k]) continue;
          if(doc[k] == to_save[k]) continue
          if(doc[k] == null || doc[k] == "")
            doc[k] = to_save[k]
          else
            console.log("flight/models-40: cannot merge property");
        }
        `
        doc.save (err, doc)->
          if err
            err.flight_mes = "r"
            process.nextTick ()->
              next(err,null)
          err = {flight_mes:"d"}
          process.nextTick ()->
            next(err, doc)

      else
        if(to_save == null)
          to_save = query
        doc = new that to_save
        doc.save (err, doc) ->
          if err
            err.flight_mes = "r"
            process.nextTick ()->
              next(err, null)
          else
            process.nextTick ()->
              next(err, doc)
  return ret






sTopic = fOCSchema(
  topic_id:
    type: String
    unique: (true)
  name:
    type: String
    unique: true
  companies: [{type: Schema.Types.ObjectId, ref:"flight_company"}]
)
sTopic.post 'remove', (doc)->
  if(doc.companies.length > 0)
    for key, value of doc.companies
      FlightCompany.update {_id: value}
      ,{ $pull: { license: doc._id } }
      ,(err)->
        if(err)
          console.log("License could not update: "+err)

sLicense = fOCSchema(
  abr:
    type: String
    unique: (true)
  #reference_num: for now reference numbers are dead
  #  type: String
  #  unique: true
  name:
    type: String
    unique: true
  full_name:
    type: String
    unique: true
  companies: [{type: Schema.Types.ObjectId, ref:"flight_company"}]
)
sLicense.post 'remove', (doc)->
  if(doc.companies.length > 0)
    for key, value of doc.companies
      FlightCompany.update {_id: value}
      ,{ $pull: { license: doc._id } }
      ,(err)->
        if(err)
          console.log("License could not update: "+err)


sRegion = fOCSchema(
  name:
    type: String
    required: true
  level:
    type: Number
    required: true
  parent:
    type: Schema.Types.ObjectId
    ref: "flight_region"
    required: false
  children: [{type: Schema.Types.ObjectId, ref:"flight_region"}]
  addresses: [{type: Schema.Types.ObjectId, ref:"flight_address"}]
)
sRegion.post 'save', (doc)->
  if(doc.parent != null)
    Region.update { _id: doc.parent }
    ,{ $addToSet: { children: doc._id } }
    ,(err)->
      if(err)
        console.log("Region Parent could not update: "+err)

sRegion.post 'remove', (doc)->
  if(doc.parent != null)
    Region.update { _id: doc.parent }
    , { $pull: { children: doc._id } } 
    ,(err)->
      if(err)
        console.log('Region Parent could not update'+err)
  if(doc.children.length > 0)
    for key, value of doc.children
      Region.update {_id: value}
      , { $set: { parent: doc.parent } }
      , (err)->
        if(err)
          console.log('Child could not update'+err)
  if(doc.addresses.length > 0)
    if(doc.parent != null)
      for key, value of doc.addresses
        Region.update {_id: value}
        , { $set: { parent: doc.parent } }
        , (err)->
          if(err)
            console.log('Address could not update'+err)
    else
      console.log("Your Flight Database has a huge problem")


sFlightCompany = fOCSchema(
  name:
    type: String
    unique: true
  url:
    type: String
    required: false
  logo_url:
    type: String
    required: false
  topic: Schema.Types.ObjectId
  license: [{type: Schema.Types.ObjectId, ref:"flight_license"}]
  addresses: [{type: Schema.Types.ObjectId, ref:"flight_address"}]
  users: [{type: Schema.Types.ObjectId, ref: "flight_user"}]
)
sFlightCompany.post 'save', (doc)->
  Topic.update { _id: doc.topic }
  ,{ $addToSet: { companies: doc._id } }
  ,(err)->
    if(err)
      console.log("Topic could not update: "+err)
  if(doc.license.length > 0)
    for key, value of doc.license
      License.update {_id: value}
      ,{ $addToSet: { companies: doc._id } }
      ,(err)->
        if(err)
          console.log("License could not update: "+err)

sFlightCompany.post 'remove', (doc)->
  Topic.update { _id: doc.topic }
  ,{ $pull: { companies: doc._id } }
  ,(err)->
    if(err)
      console.log("Topic could not update: "+err)
  if(doc.license.length > 0)
    for key, value of doc.license
      License.update {_id: value}
      ,{ $pull: { companies: doc._id } }
      ,(err)->
        if(err)
          console.log("License could not update: "+err)

sAddress = fOCSchema(
  address: String
  post_code: String
  telephone_number:
    type: Number
    required:false
  fax_number:
    type: String
    required: false
  email:
    type: String
    required: false
  company: {type: Schema.Types.ObjectId, ref:"flight_company"}
  region: {type: Schema.Types.ObjectId, ref:"flight_region"}
  users: [{type: Schema.Types.ObjectId, ref:"flight_user"}]
)
sAddress.post 'save', (doc)->
  FlightCompany.update { _id: doc.company }
  ,{ $addToSet: { addresses: doc._id } }
  ,(err)->
    if(err)
      console.log("Company could not update: "+err)
  Region.update { _id: doc.region }
  ,{ $addToSet: { addresses: doc._id } }
  ,(err)->
    if(err)
      console.log("Region could not update: "+err)
sAddress.post 'remove', (doc)->
  FlightCompany.update { _id: doc.company }
  ,{ $pull: { addresses: doc._id } }
  ,(err)->
    if(err)
      console.log("Company could not update: "+err)
  Region.update { _id: doc.region }
  ,{ $pull: { addresses: doc._id } }
  ,(err)->
    if(err)
      console.log("Region could not update: "+err)
  if(doc.user.length > 0)
    for key, value of doc.user
      User.update {_id: value}
      ,{ $pull: { companies: doc._id } }
      ,(err)->
        if(err)
          console.log("Company Member could not update: "+err)

sUser = fOCSchema(
  company:
    type: Schema.Types.ObjectId
    ref: "flight_company"
    required: true
  address:
    type: Schema.Types.ObjectId
    ref: "flight_region"
    required: true
  info:
    type: Schema.Types.ObjectId
    required: false
)
sUser.post 'save', (doc)->
  Address.update { _id: doc.address }
  ,{ $addToSet: { users: doc._id } }
  ,(err)->
    if(err)
      console.log("Address could not update: "+err)
  FlightCompany.update { _id: doc.company }
  ,{ $addToSet: { users: doc._id } }
  ,(err)->
    if(err)
      console.log("Company could not update: "+err)
sUser.post 'remove', (doc)->
  FlightCompany.update { _id: doc.company }
  ,{ $pull: { users: doc._id } }
  ,(err)->
    if(err)
      console.log("Company could not update: "+err)
  Address.update { _id: doc.address }
  ,{ $pull: { users: doc._id } }
  ,(err)->
    if(err)
      console.log("Address could not update: "+err)

Topic = mongoose.model "flight_topic", sTopic
License = mongoose.model "flight_license", sLicense
FlightCompany = mongoose.model "flight_company", sFlightCompany
Address = mongoose.model "flight_address", sAddress
Region = mongoose.model "flight_region", sRegion
User = mongoose.model "flight_user", sUser
module.exports =
  topic : Topic
  license : License
  company : FlightCompany
  address : Address
  region : Region
  user : User