class ApisController < ApplicationController
	
	skip_before_action :verify_authenticity_token, :only => [:update_state]

	def update_state

		begin
			if (request.headers["token"]) != ENV['secret']
				render json: {
					status: 403,
					message: "Your are not allowed Sir"
				}.to_json and return
			else
				parsed_json = JSON.parse(params["selDossiers"])

				parsed_json["selDossiers"].each do |dossier|

					if dossier["properties"]

						projet = Projet.find_by(:opal_numero => dossier["properties"]["numero"])

						if projet
							
							opalPosition = dossier["properties"]["position"]
							opalDatePosition = dossier["properties"]["date"]
							opalPositionLabel = ""

							if opalPosition == "10058"
								opalPositionLabel = "En cours d'instruction"

							elsif opalPosition == "8"
								opalPositionLabel = "Accordé"

							elsif opalPosition == "10"
								opalPositionLabel = "Rejeté"

							elsif opalPosition == "10060"
								opalPositionLabel = "Classé sans suite"

							elsif opalPosition == "10055"
								opalPositionLabel = "Aide retirée"

							elsif opalPosition == "10072"
								opalPositionLabel = "Aide retirée avec reversement"

							elsif opalPosition == "10015"
								opalPositionLabel = "Acompte Deposée en attente d'instruction"

							elsif opalPosition == "10053"
								opalPositionLabel = "Acompte Payé"

							elsif opalPosition == "10075"
								opalPositionLabel = "Avance Deposée en attente d'instruction"

							elsif opalPosition == "10076"
								opalPositionLabel = "Avance Payée"

							elsif opalPosition == "10016"
								opalPositionLabel = "Solde Deposée en attente d'instruction"

							elsif opalPosition == "10056"
								opalPositionLabel = "Demande solde supplementaire"

							elsif opalPosition == "10033"
								opalPositionLabel = "Solde Payée"
							end


							if opalPositionLabel != "" && opalDatePosition != "" && opalDatePosition != nil
								projet.update(:position_opal => opalPositionLabel, :opal_date_position => opalDatePosition)
							end
						end
					end
				end

				render json: {
					status: 200,
					message: "Update okay Sir"
				}.to_json and return
			end

		rescue
			render json: {
				status: 412,
				message: "Une erreur a eu lieu côté Serveur Sir"
			}.to_json and return
		end
	end
end
