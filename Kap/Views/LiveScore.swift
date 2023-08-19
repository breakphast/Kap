//
//  LiveScore.swift
//  Kap
//
//  Created by Desmond Fitch on 8/18/23.
//

import Foundation

// MARK: - LiveScoreElement
struct LiveScoreElement: Codable {
    let gameKey: String
    let seasonType, season, week: Int
    let date, awayTeam, homeTeam: String
    let awayScore, homeScore: JSONNull?
    let channel: String?
    let pointSpread, overUnder, quarter, timeRemaining: JSONNull?
    let possession, down: JSONNull?
    let distance: Distance
    let yardLine, yardLineTerritory, redZone, awayScoreQuarter1: JSONNull?
    let awayScoreQuarter2, awayScoreQuarter3, awayScoreQuarter4, awayScoreOvertime: JSONNull?
    let homeScoreQuarter1, homeScoreQuarter2, homeScoreQuarter3, homeScoreQuarter4: JSONNull?
    let homeScoreOvertime: JSONNull?
    let hasStarted, isInProgress, isOver, has1StQuarterStarted: Bool
    let has2NdQuarterStarted, has3RDQuarterStarted, has4ThQuarterStarted, isOvertime: Bool
    let downAndDistance: JSONNull?
    let quarterDescription: String
    let stadiumID: Int
    let lastUpdated: LastUpdated
    let geoLat, geoLong, forecastTempLow, forecastTempHigh: JSONNull?
    let forecastDescription, forecastWindChill, forecastWindSpeed, awayTeamMoneyLine: JSONNull?
    let homeTeamMoneyLine: JSONNull?
    let canceled, closed: Bool
    let lastPlay: Distance
    let day, dateTime: String
    let awayTeamID, homeTeamID, globalGameID, globalAwayTeamID: Int
    let globalHomeTeamID: Int
    let pointSpreadAwayTeamMoneyLine, pointSpreadHomeTeamMoneyLine: JSONNull?
    let scoreID: Int
    let status: Status
    let gameEndDateTime, homeRotationNumber, awayRotationNumber: JSONNull?
    let neutralVenue: Bool
    let refereeID, overPayout, underPayout, homeTimeouts: JSONNull?
    let awayTimeouts: JSONNull?
    let dateTimeUTC: String
    let attendance: Int
    let isClosed: Bool
    let stadiumDetails: StadiumDetails

    enum CodingKeys: String, CodingKey {
        case gameKey = "GameKey"
        case seasonType = "SeasonType"
        case season = "Season"
        case week = "Week"
        case date = "Date"
        case awayTeam = "AwayTeam"
        case homeTeam = "HomeTeam"
        case awayScore = "AwayScore"
        case homeScore = "HomeScore"
        case channel = "Channel"
        case pointSpread = "PointSpread"
        case overUnder = "OverUnder"
        case quarter = "Quarter"
        case timeRemaining = "TimeRemaining"
        case possession = "Possession"
        case down = "Down"
        case distance = "Distance"
        case yardLine = "YardLine"
        case yardLineTerritory = "YardLineTerritory"
        case redZone = "RedZone"
        case awayScoreQuarter1 = "AwayScoreQuarter1"
        case awayScoreQuarter2 = "AwayScoreQuarter2"
        case awayScoreQuarter3 = "AwayScoreQuarter3"
        case awayScoreQuarter4 = "AwayScoreQuarter4"
        case awayScoreOvertime = "AwayScoreOvertime"
        case homeScoreQuarter1 = "HomeScoreQuarter1"
        case homeScoreQuarter2 = "HomeScoreQuarter2"
        case homeScoreQuarter3 = "HomeScoreQuarter3"
        case homeScoreQuarter4 = "HomeScoreQuarter4"
        case homeScoreOvertime = "HomeScoreOvertime"
        case hasStarted = "HasStarted"
        case isInProgress = "IsInProgress"
        case isOver = "IsOver"
        case has1StQuarterStarted = "Has1stQuarterStarted"
        case has2NdQuarterStarted = "Has2ndQuarterStarted"
        case has3RDQuarterStarted = "Has3rdQuarterStarted"
        case has4ThQuarterStarted = "Has4thQuarterStarted"
        case isOvertime = "IsOvertime"
        case downAndDistance = "DownAndDistance"
        case quarterDescription = "QuarterDescription"
        case stadiumID = "StadiumID"
        case lastUpdated = "LastUpdated"
        case geoLat = "GeoLat"
        case geoLong = "GeoLong"
        case forecastTempLow = "ForecastTempLow"
        case forecastTempHigh = "ForecastTempHigh"
        case forecastDescription = "ForecastDescription"
        case forecastWindChill = "ForecastWindChill"
        case forecastWindSpeed = "ForecastWindSpeed"
        case awayTeamMoneyLine = "AwayTeamMoneyLine"
        case homeTeamMoneyLine = "HomeTeamMoneyLine"
        case canceled = "Canceled"
        case closed = "Closed"
        case lastPlay = "LastPlay"
        case day = "Day"
        case dateTime = "DateTime"
        case awayTeamID = "AwayTeamID"
        case homeTeamID = "HomeTeamID"
        case globalGameID = "GlobalGameID"
        case globalAwayTeamID = "GlobalAwayTeamID"
        case globalHomeTeamID = "GlobalHomeTeamID"
        case pointSpreadAwayTeamMoneyLine = "PointSpreadAwayTeamMoneyLine"
        case pointSpreadHomeTeamMoneyLine = "PointSpreadHomeTeamMoneyLine"
        case scoreID = "ScoreID"
        case status = "Status"
        case gameEndDateTime = "GameEndDateTime"
        case homeRotationNumber = "HomeRotationNumber"
        case awayRotationNumber = "AwayRotationNumber"
        case neutralVenue = "NeutralVenue"
        case refereeID = "RefereeID"
        case overPayout = "OverPayout"
        case underPayout = "UnderPayout"
        case homeTimeouts = "HomeTimeouts"
        case awayTimeouts = "AwayTimeouts"
        case dateTimeUTC = "DateTimeUTC"
        case attendance = "Attendance"
        case isClosed = "IsClosed"
        case stadiumDetails = "StadiumDetails"
    }
}

enum Distance: String, Codable {
    case scrambled = "Scrambled"
}

enum LastUpdated: String, Codable {
    case the20230810T134155 = "2023-08-10T13:41:55"
}

// MARK: - StadiumDetails
struct StadiumDetails: Codable {
    let stadiumID: Int
    let name, city, state: String
    let country: Country
    let capacity: Int
    let playingSurface: PlayingSurface
    let geoLat, geoLong: Double
    let type: TypeEnum

    enum CodingKeys: String, CodingKey {
        case stadiumID = "StadiumID"
        case name = "Name"
        case city = "City"
        case state = "State"
        case country = "Country"
        case capacity = "Capacity"
        case playingSurface = "PlayingSurface"
        case geoLat = "GeoLat"
        case geoLong = "GeoLong"
        case type = "Type"
    }
}

enum Country: String, Codable {
    case usa = "USA"
}

enum PlayingSurface: String, Codable {
    case artificial = "Artificial"
    case grass = "Grass"
}

enum TypeEnum: String, Codable {
    case dome = "Dome"
    case outdoor = "Outdoor"
    case retractableDome = "RetractableDome"
}

enum Status: String, Codable {
    case scheduled = "Scheduled"
}

typealias LiveScore = [LiveScoreElement]

// MARK: - Encode/decode helpers

class JSONNull: Codable, Hashable {

    public static func == (lhs: JSONNull, rhs: JSONNull) -> Bool {
        return true
    }

    public var hashValue: Int {
        return 0
    }

    public init() {}

    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if !container.decodeNil() {
            throw DecodingError.typeMismatch(JSONNull.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}
