class_name BuildingResource
extends Resource

@export var building_name: String
@export var building_description: String
@export var construction_cost: int = 5
@export var jobs: Array[Job]


func dupe() -> BuildingResource:
	var duped: BuildingResource = duplicate(true)
	var duped_jobs: Array[Job]
	for job in jobs:
		duped_jobs.append(job.dupe())
	duped.jobs = duped_jobs
	return(duped)
