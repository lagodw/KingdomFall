extends Resource

func complete_construction(trigger_card: Building):
	var resource = trigger_card.resource
	for job in resource.jobs:
		if job.description == "Construction":
			resource.jobs.erase(job)
