//
//  EditRows.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents
import VinOutlineKit

struct EditRowsAppIntent: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent, ZavalaAppIntent {
    static let intentClassName = "EditRowsIntent"
    static let title: LocalizedStringResource = "Edit Rows"
    static let description = IntentDescription("Update the details of a Row.")

    @Parameter(title: "Rows")
	var rows: [RowAppEntity]

    @Parameter(title: "Detail")
    var detail: RowDetailAppEnum

    @Parameter(title: "Topic")
    var topic: String?

    @Parameter(title: "Note")
    var note: String?

    @Parameter(title: "Complete")
    var complete: Bool?

    @Parameter(title: "Expanded")
    var expanded: Bool?

    static var parameterSummary: some ParameterSummary {
        Switch(\.$detail) {
            Case(.topic) {
                Summary("Set \(\.$detail) of \(\.$rows) to \(\.$topic)")
            }
            Case(.note) {
                Summary("Set \(\.$detail) of \(\.$rows) to \(\.$note)")
            }
            Case(.complete) {
                Summary("Set \(\.$detail) of \(\.$rows) to \(\.$complete)")
            }
            Case(.expanded) {
                Summary("Set \(\.$detail) of \(\.$rows) to \(\.$expanded)")
            }
            DefaultCase {
                Summary("Set \(\.$detail) of \(\.$rows)")
            }
        }
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$rows, \.$detail, \.$topic)) { rows, detail, topic in
            DisplayRepresentation(
                title: "Set \(detail) of \(rows, format: .list(type: .and)) to \(topic!)",
                subtitle: ""
            )
        }
        IntentPrediction(parameters: (\.$rows, \.$detail, \.$note)) { rows, detail, note in
            DisplayRepresentation(
                title: "Set \(detail) of \(rows, format: .list(type: .and)) to \(note!)",
                subtitle: ""
            )
        }
        IntentPrediction(parameters: (\.$rows, \.$detail, \.$complete)) { rows, detail, complete in
            DisplayRepresentation(
                title: "Set \(detail) of \(rows, format: .list(type: .and)) to \(String(describing: complete!))",
                subtitle: ""
            )
        }
        IntentPrediction(parameters: (\.$rows, \.$detail, \.$expanded)) { rows, detail, expanded in
            DisplayRepresentation(
                title: "Set \(detail) of \(rows, format: .list(type: .and)) to \(String(describing: expanded!))",
                subtitle: ""
            )
        }
        IntentPrediction(parameters: (\.$rows, \.$detail)) { rows, detail in
            DisplayRepresentation(
                title: "Set \(detail) of \(rows, format: .list(type: .and))",
                subtitle: ""
            )
        }
    }

	@MainActor
    func perform() async throws -> some IntentResult {
		resume()
		
		var outlines = Set<Outline>()
		
		let rows: [Row] = self.rows
			.compactMap { $0.entityID }
			.compactMap {
				if let rowOutline = AccountManager.shared.findDocument($0)?.outline {
					rowOutline.load()
					outlines.insert(rowOutline)
					return rowOutline.findRow(id: $0.rowUUID)
				}
				return nil
			}
		
		for row in rows {
			switch detail {
			case .topic:
				if let markdown = topic {
					row.outline?.updateRow(row, rowStrings: .topicMarkdown(markdown), applyChanges: true)
				}
			case .note:
				if let markdown = note, !markdown.isEmpty {
					row.outline?.updateRow(row, rowStrings: .noteMarkdown(markdown), applyChanges: true)
				} else {
					row.outline?.deleteNotes(rows: [row])
				}
			case .complete:
				if let complete {
					if complete {
						row.outline?.complete(rows: [row])
					} else {
						row.outline?.uncomplete(rows: [row])
					}
				}
			case .expanded:
				if let expanded {
					if expanded {
						row.outline?.expand(rows: [row])
					} else {
						row.outline?.collapse(rows: [row])
					}
				}
			}
			
			row.detectData()
		}
		
		for outline in outlines {
			await outline.unload()
		}

		await suspend()
        return .result()
    }
}

