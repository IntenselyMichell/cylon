###
 * robot
 * cylonjs.com
 *
 * Copyright (c) 2013 The Hybrid Group
 * Licensed under the Apache 2.0 license.
###

'use strict';

require('./cylon')
Connection = require("./connection")
Device = require("./device")

module.exports = class Robot
  self = this
  @adaptors = {}

  constructor: (opts = {}) ->
    @name = opts.name or @constructor.randomName()
    @master = opts.master
    @connections = {}
    @devices = {}

    @registerAdaptor "./loopback", "loopback"

    @initConnections(opts.connection or opts.connections)
    @initDevices(opts.device or opts.devices)
    @work = opts.work or -> (Logger.info "No work yet")

  @randomName: ->
    "Robot #{ Math.floor(Math.random() * 100000) }"

  initConnections: (connections) ->
    Logger.info "Initializing connections..."
    return unless connections?
    connections = [].concat connections
    for connection in connections
      Logger.info "Initializing connection '#{ connection.name }'..."
      connection['robot'] = self
      @connections[connection.name] = new Connection(connection)

  initDevices: (devices) ->
    Logger.info "Initializing devices..."
    return unless devices?
    devices = [].concat devices
    for device in devices
      Logger.info "Initializing device '#{ device.name }'..."
      device['robot'] = self
      @devices[device.name] = new Device(device)

  start: ->
    @startConnections()
    @startDevices()
    @work.call(self, self)

  startConnections: ->
    Logger.info "Starting connections..."
    for n, connection of self.connections
      Logger.info "Starting connection '#{ connection.name }'..."
      connection.connect()
      self[connection.name] = connection

  startDevices: ->
    Logger.info "Starting devices..."
    for n, device of self.devices
      Logger.info "Starting device '#{ device.name }'..."
      device.start()
      self[device.name] = device

  @requireAdaptor = (adaptorName, connection) ->
    require("cylon-#{adaptorName}").register(self) unless self.adaptors[adaptorName]?
    require(self.adaptors[adaptorName]).adaptor(name: adaptorName).connect(connection: connection)

  registerAdaptor: (moduleName, adaptorName) ->
    return if self.adaptors[adaptorName]?
    self.adaptors[adaptorName] = moduleName

  requireDriver: (driverName, device) ->
    require("cylon-#{@drivers[driverName]}").register(self) unless @drivers[driverName]?
    require(@drivers[driverName]).driver(driverName)(device: device)

  registerDriver: (moduleName, driverName) ->
    @drivers ?= {}
    return if @drivers[driverName]?
    @drivers[driverName] = moduleName
