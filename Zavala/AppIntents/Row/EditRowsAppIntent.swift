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
    static let title: LocalizedStringResource = LocalizedStringResource("intent.title.edit-rows", comment: "Edit Rows")
    static let description = IntentDescription(LocalizedStringResource("intent.descrption.update-row-details", comment: "Update the details of a Row"))

    @Parameter(title: LocalizedStringResource("intent.parameter.rows", comment: "Rows"))
	var rows: [RowAppEntity]

    @Parameter(title: LocalizedStringResource("intent.parameter.detail", comment: "Detail"))
    var detail: RowDetailAppEnum

    @Parameter(title: LocalizedStringResource("intent.parameter.topic", comment: "Topic"))
    var topic: String?

    @Parameter(title: LocalizedStringResource("intent.parameter.note", comment: "Note"))
    var note: String?

    @Parameter(title: LocalizedStringResource("intent.parameter.complete", comment: "Complete"))
    var complete: Bool?

    @Parameter(title: LocalizedStringResource("intent.parameter.expanded", comment: "Expanded"))
    var expanded: Bool?

    static var parameterSummary: some ParameterSummary {
        Switch(\.$detail) {
            Case(.topic) {
                Summary("intent.summary.set-\(\.$detail)-of-\(\.$rows)-to-\(\.$topic)")
            }
            Case(.note) {
                Summary("intent.summary.set-\(\.$detail)-of-\(\.$rows)-to-\(\.$note)")
            }
            Case(.complete) {
                Summary("intent.summary.set-\(\.$detail)-of-\(\.$rows)-to-\(\.$complete)")
            }
            Case(.expanded) {
                Summary("intent.summary.set-\(\.$detail)-of-\(\.$rows)-to-\(\.$expanded)")
            }
            DefaultCase {
                Summary("intent.summary.set-\(\.$detail)-of-\(\.$rows)")
            }
        }
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$rows, \.$detail, \.$topic)) { rows, detail, topic in
            DisplayRepresentation(
				title: LocalizedStringResource("intent.prediction.set-\(detail)-of-\(rows, format: .list(type: .and))-to-\(topic!)", comment: "Set <detail> of <rows> to <topic>"),
                subtitle: nil
            )
        }
        IntentPrediction(parameters: (\.$rows, \.$detail, \.$note)) { rows, detail, note in
            DisplayRepresentation(
                title: LocalizedStringResource("intent.prediction.set-\(detail)-of-\(rows, format: .list(type: .and))-to-\(note!)", comment: "Set <detail> of <rows> to <note>"),
                subtitle: nil
            )
        }
        IntentPrediction(parameters: (\.$rows, \.$detail, \.$complete)) { rows, detail, complete in
            DisplayRepresentation(
				title: LocalizedStringResource("intent.prediction.set-\(detail)-of-\(rows, format: .list(type: .and))-to-\(String(describing: complete!))", comment: "Set <detail> of <rows> to <complete>"),
                subtitle: nil
            )
        }
        IntentPrediction(parameters: (\.$rows, \.$detail, \.$expanded)) { rows, detail, expanded in
			DisplayRepresentation(
                title: LocalizedStringResource("intent.prediction.set-\(detail)-of-\(rows, format: .list(type: .and))-to-\(String(describing:expanded!))", comment: "Set <detail> of <rows> to <expanded>"),
                subtitle: nil
            )
        }
        IntentPrediction(parameters: (\.$rows, \.$detail)) { rows, detail in
			DisplayRepresentation(
                title: LocalizedStringResource("intent.prediction.set-\(detail)-of-\(rows, format: .list(type: .and))", comment: "Set <detail> of <rows>"),
                subtitle: nil
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
				if let rowOutline = appDelegate.accountManager.findDocument($0)?.outline {
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

