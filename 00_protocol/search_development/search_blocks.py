"""Search blocks shared by every database script (one source of truth for the words)."""

# VERSION 2 (2026-10-27). v1 (same day, logged) gave 24k + 32k hits: generic words (street, park, trees,
# maintenance, visibility, disorder, refuge, crime) pulled in unrelated work ("disorder" = mental disorders,
# "refuge" = shelters). v1 also missed Adamczak 2025, which names no design feature. v2: precise feature phrases,
# specific harm terms, and S4 (outcome AND women AND place) to catch gender-focused studies without a feature word.
VERSION = "v2"
FEATURE = ['lighting', 'illumination', '"street lights"', '"street lighting"', '"street lamps"', 'vegetation',
           'greenery', '"green space"', '"green spaces"', 'landscaping', 'sightlines', '"sight lines"',
           '"prospect-refuge"', '"prospect and refuge"', 'entrapment', 'concealment', '"active frontage"',
           '"active frontages"', '"shop fronts"', '"mixed use"', '"mixed-use"', 'incivilities', '"physical disorder"',
           '"neighborhood disorder"', '"neighbourhood disorder"', '"social disorder"', 'graffiti', 'litter',
           '"broken windows"', '"presence of others"', '"presence of people"', '"natural surveillance"',
           '"eyes on the street"', '"built environment"', '"urban design"', '"environmental design"', 'CPTED',
           '"physical environment"']
PERCEIVED = ['"perceived safety"', '"fear of crime"', '"feeling of safety"', '"feelings of safety"',
             '"sense of safety"', '"perception of safety"', '"perceptions of safety"', '"perceived security"',
             '"feeling safe"', '"feel safe"', '"feelings of insecurity"', 'reassurance', '"perceived danger"',
             '"perceived risk of crime"', '"fear of victimization"', '"fear of victimisation"']
ACTUAL = ['"sexual harassment"', '"street harassment"', '"sexual assault"', '"sexual violence"',
          '"violence against women"', '"gender-based violence"', '"crime against women"', '"crimes against women"',
          'victimization', 'victimisation', 'rape']
WOMEN = ['women', 'woman', 'female', 'females', 'gender', 'girls', '"sex differences"']
PLACE = ['environment', 'environments', '"public space"', '"public spaces"', 'park', 'parks', 'street', 'streets',
         'neighbourhood', 'neighborhood', 'urban', 'city', 'transport', 'transit']
FR = ['"sentiment de sécurité"', "\"sentiment d'insécurité\"", '"peur du crime"', '"harcèlement de rue"']

STRATEGIES = {
    "S1_feature_x_perceived": [FEATURE, PERCEIVED],
    "S2_feature_x_actual_x_women": [FEATURE, ACTUAL, WOMEN],
    "S3_french_outcomes": [FR],
    "S4_perceived_x_women_x_place": [PERCEIVED, WOMEN, PLACE],
}
UNION = ["S1_feature_x_perceived", "S2_feature_x_actual_x_women", "S4_perceived_x_women_x_place"]

# Benchmarks: primary studies we expect to be eligible, fixed before running the test.
# Chosen from titles only (Step 0 notes and Knabe et al. reference list); their results were not read.
BENCHMARKS = {
    "Boomsma & Steg 2014": "10.1177/0013916512453838",
    "Baran et al. 2018": "10.1016/j.ufug.2018.08.009",
    "Basu et al. 2021": "10.1016/j.jth.2021.101243",
    "Navarrete-Hernandez et al. 2025": "10.1016/j.landurbplan.2025.105460",
    "Adamczak et al. 2025": "10.1016/j.jenvp.2025.102752",
    "Brands et al. 2025": "10.1093/bjc/azae072",
    "Basaran et al. 2026": "10.1016/j.cities.2026.106873",
}



