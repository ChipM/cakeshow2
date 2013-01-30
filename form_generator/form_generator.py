import json, sys, calendar
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import letter
from reportlab.lib.units import inch

def generate_judging_form(canvas, signup, entry):
	header(canvas, signup, entry)
	if (entry.get('category') == 'Showcakes'):
		judging_showcake_body(canvas)
	else:
		judging_divisional_body(canvas)
	

def header(canvas, signup, entry):
	year = signup.get('year')
	
	# Prints Show info
	canvas.setFont("Helvetica-Bold", 20)
	canvas.drawString(inch, 10 * inch, "That Takes the Cake! " + str(year))
	canvas.setFont("Helvetica", 14)
	canvas.drawString(inch, 9.75 * inch, "Cake & Sugar Art Show & Competition")
	canvas.drawString(inch, 9.50 * inch, "Capital Confectioners, Austin, TX")
	
	# Calculate date of show; Monday = 0
	last_day = calendar.weekday(int(year), 2, 28)
	saturday = 28 - last_day - 2
	saturday = "February " + str(saturday)
	sunday = 28 - last_day - 1
	# If the 28th is on a Saturday and not a leap year
	if (last_day == 5) and (not calendar.isleap(year)):
		sunday = "March 1"
	else:
		sunday = str(sunday)
	
	canvas.drawString(inch, 9.25 * inch, saturday + " & " + sunday + ", " + str(year))
	
	# Print entry number, division & category
	canvas.drawString(6.5 * inch, 10 * inch, "Entry #" + str(entry.get('id')))
	if (entry.get('category') == 'Showcakes'):
		canvas.drawString(6.5 * inch, 9.75 * inch, entry.get('category'))
	else:
		# Class doesn't apply to the tasting category
		category = entry.get('category')
		if ((category.find("Tasting") >= 0) or (category.find("tasting") >= 0)):
			canvas.drawString(6.5 * inch, 9.75 * inch, entry.get('category'))
		else:
			canvas.drawString(6.5 * inch, 9.75 * inch, signup.get('class'))
			canvas.drawString(6.5 * inch, 9.50 * inch, entry.get('category'))

def judging_divisional_body(canvas):
	criteria = ["Precision", "Originality", "Creativity", "Skill", "Color", "Design", "Difficulty", "Number of Techniques", "Overall Eye Appeal"]
#	canvas.drawString(4.5 * inch, 8.75 * inch, "Divisional Competition")
	
	# Table header
	canvas.drawString(3.30 * inch, 8.375 * inch, "    Needs")
	canvas.drawString(3.30 * inch, 8.125 * inch, "Improvement")
	canvas.drawString(4.85 * inch, 8.25 * inch, "Fair")
	canvas.drawString(5.750 * inch, 8.25 * inch, "Good")
	canvas.drawString(6.750 * inch, 8.25 * inch, "Excellent")
	
	# Display column of criteria
	offset = 7.75
	for criterium in criteria:
		canvas.drawString(1.125 * inch, offset * inch, criterium)
		offset -= 0.375
	
	# Build up rows
	rows = []
	offset = 8.00
	for criterium in criteria:
		rows.append(offset * inch)
		offset -= 0.375
	rows.append(offset * inch)
	
	# Draw grid
	canvas.grid([inch, 3.25*inch, 4.50*inch, 5.50*inch, 6.50*inch, 7.75*inch], rows)
	
	
	# Display comments section
	offset -= 0.5
	canvas.drawString(inch, offset * inch, "Comments: ")
	canvas.line(2.25 * inch, offset * inch, 7.5 * inch, offset * inch)
	
	while (offset > 1.5):
		offset -= 0.5
		canvas.line(1 * inch, offset * inch, 7.5 * inch, offset * inch)
	

def judging_showcake_body(canvas):
	criteria = ["Application of Theme", "Precision of Techniques", "Originality & Creativity", "Appropriate Design (size, shape, colors, etc.)", "Difficulty of Techniques", "Number of Techniques Used", "Overall Eye Appeal (Judge's discretion)"]
	maximum_points = [15, 15, 15, 15, 15, 15, 10]
	
	# Table header
	canvas.drawString(5.85 * inch, 8.375 * inch, "Maximum")
	canvas.drawString(5.85 * inch, 8.125 * inch, "  Points")
	canvas.drawString(6.85 * inch, 8.375 * inch, "  Points")
	canvas.drawString(6.85 * inch, 8.125 * inch, "Awarded")
	
	# Display column of criteria
	offset = 7.75
	index = 0
	for criterium in criteria:
		canvas.drawString(1.125 * inch, offset * inch, criterium)
		canvas.drawString(6.125 * inch, offset * inch, str(maximum_points[index]))
		offset -= 0.375
		index += 1
	canvas.drawString(6.125 * inch, offset * inch, "Total:")
	
	# Build up rows
	rows = []
	offset = 8.00
	for criterium in criteria:
		rows.append(offset * inch)
		offset -= 0.375
	rows.append(offset * inch)
	
	# Draw grid
	canvas.grid([inch, 5.75*inch, 6.75*inch, 7.75*inch], rows)
	canvas.grid([6.75*inch, 7.75*inch], [offset * inch, (offset - 0.375) * inch])
	offset -= 0.375
	
	# Display comments section
	offset -= 0.5
	canvas.drawString(inch, offset * inch, "Comments: ")
	canvas.line(2.25 * inch, offset * inch, 7.5 * inch, offset * inch)
	
	while (offset > 1.5):
		offset -= 0.5
		canvas.line(1 * inch, offset * inch, 7.5 * inch, offset * inch)

def generate_entry_form(canvas, signup, entry, registrant):
	line_count = 4
	header(canvas, signup, entry)
	
	canvas.drawString(inch, 8.0 * inch, "Entry Title:")
	canvas.line(2.25 * inch, 8.0 * inch, 7.5 * inch, 8.0 * inch)
	
	# Leave blank for tasting recipe
	category = entry.get('category')
	if ((category.find("Tasting") >= 0) or (category.find("tasting") >= 0)):
		canvas.drawString(inch, 7.5 * inch, "Recipe:")
	else:
		canvas.drawString(inch, 7.5 * inch, "Description:")
		canvas.line(2.25 * inch, 7.5 * inch, 7.5 * inch, 7.5 * inch)
	
		canvas.drawString(inch, 7.0 * inch, "Techniques Used:")
		line_num = 0
		offset = 6.5
		while (line_num < line_count):
			canvas.line(inch, offset * inch, 7.5 * inch, offset * inch)
			offset -= 0.5
			line_num += 1
	
		canvas.drawString(inch, offset * inch, "Media Used:")
		line_num = 0
		offset -= 0.5
		while (line_num < line_count):
			canvas.line(inch, offset * inch, 7.5 * inch, offset * inch)
			offset -= 0.5
			line_num += 1
	
	# print entry numbers on the labels
	canvas.drawString(0.75 * inch, inch, str(entry.get('id')))
	canvas.drawString(2.75 * inch, inch, str(entry.get('id')))
	canvas.drawString(4.75 * inch, inch, str(entry.get('id')))
	canvas.drawString(7.00 * inch, 1.125 * inch, str(entry.get('id')))
	
	# print name on last label
	canvas.setFont("Helvetica", 10)
	canvas.drawString(6.5 * inch, 0.90 *inch, str(registrant.get('firstname')))
	canvas.drawString(6.5 * inch, 0.75 *inch, str(registrant.get('lastname')))

if __name__ == "__main__":
	if (len(sys.argv) != 3): 
		print "ERROR: Must provide two parameters: JSON_FILE OUTPUT_DIR"
		sys.exit(2)
	json_file = str(sys.argv[1])
	output_file = str(sys.argv[2])
	
	try: 
		json_data = open(json_file)
		data = json.load(json_data)
	except IOError as e:
		print "I/O error({0}): {1}".format(e.errno, e.strerror)
		sys.exit(2)
	
	canvas = canvas.Canvas(output_file, pagesize=letter)
	for contestant in data:
		# Put all of the contestant's entry forms together
		for entry in contestant.get('entries'):
			# Do tasting entries need this?
			generate_entry_form(canvas, contestant.get('signup'), entry, contestant.get('registrant'))
			canvas.showPage()
		# Put all of the contestant's judging sheets together
		for entry in contestant.get('entries'):
			generate_judging_form(canvas, contestant.get('signup'), entry)
			canvas.showPage()
	canvas.save()