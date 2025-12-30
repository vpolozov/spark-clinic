Account.destroy_all
Patient.destroy_all
Observation.destroy_all

rrs = {
  'blood_pressure' => { 'unit' => 'mmHg',
                       'systolic' => { 'low' => 90, 'high' => 160 },
                       'diastolic' => { 'low' => 60, 'high' => 100 } },
  'glucose' => { 'unit' => 'mg/dL', 'low' => 70, 'high' => 150 },
  'weight' => { 'unit' => 'kg', 'low' => 60, 'high' => 120 }
}

a1 = Account.create!(name: "Blue Clinic", settings: {
  theme: "blue",
  reference_ranges: rrs,
  webhook_url: "/dev/webhook_sink"
})
a2 = Account.create!(name: "Green Clinic", settings: {
  theme: "green",
  bp_systolic_high: 160, bp_diastolic_high: 100, glucose_high: 150,
  webhook_url: "/dev/webhook_sink"
})
a3 = Account.create!(name: "Pecan Clinic", settings: {
  theme: "light",
  reference_ranges: rrs,
  webhook_url: "https://webhook.site/9031a77b-9b46-4f44-a0aa-29cc74f33a5b" # https://webhook.site/#!/view/9031a77b-9b46-4f44-a0aa-29cc74f33a5b
})

def create_patient!(account, id, name)
  account.patients.create!(external_id: id, name: name, dob: Date.new(1980, 1, 1))
end

p1 = create_patient!(a1, "PT-1001", "Alice")
p2 = create_patient!(a1, "PT-1002", "Bob")
p3 = create_patient!(a2, "PT-2001", "Carlos")
p4 = create_patient!(a3, "PT-3001", "John Doe")
p5 = create_patient!(a3, "PT-3002", "Moris Trail")

def weight!(acct, pat, val, t, unit: 'kg')
  Observation::Weight.create!(account: acct, patient: pat, code: 'WEIGHT',
                              value: val, unit: unit, recorded_at: t)
end

def glucose!(acct, pat, val, t, unit: 'mg/dL')
  Observation::Glucose.create!(account: acct, patient: pat, code: 'GLU',
                               value: val, unit: unit, recorded_at: t)
end

def bp!(acct, pat, sys, dia, t)
  Observation::BloodPressure.create!(account: acct, patient: pat, code: 'BP',
                                     systolic: sys, diastolic: dia, unit: 'mmHg', recorded_at: t)
end

now = Time.now.utc

# Alice (Blue Clinic)
weight!(a1, p1, 70.2, now - 3.days)
weight!(a1, p1, 70.6, now - 2.days)
weight!(a1, p1, 70.4, now - 1.day)

glucose!(a1, p1, 95,  now - 12.hours)
glucose!(a1, p1, 142, now - 6.hours)

a1_bp_times = [ now - 36.hours, now - 18.hours, now - 2.hours ]
[ [ 120, 80 ], [ 138, 88 ], [ 182, 112 ] ].zip(a1_bp_times).each do |(s, d), t|
  bp!(a1, p1, s, d, t)
end

# Bob (Blue Clinic)
weight!(a1, p2, 82.0, now - 5.days)
weight!(a1, p2, 81.5, now - 2.days)

glucose!(a1, p2, 110, now - 1.day)

a1_bp_times_bob = [ now - 30.hours, now - 8.hours ]
[ [ 128, 84 ], [ 150, 95 ] ].zip(a1_bp_times_bob).each do |(s, d), t|
  bp!(a1, p2, s, d, t)
end

# Carlos (Green Clinic)
weight!(a2, p3, 68.3, now - 4.days)

glucose!(a2, p3, 180, now - 3.hours)

bp!(a2, p3, 160, 100, now - 4.hours)

# John (Pecan Clinic)

bp!(a3, p4, 160, 100, now - 1.hour)

# Moris (Pecan Clinic)

weight!(a3, p5, 88.6, now - 4.days)

glucose!(a3, p5, 120, now - 3.hours)

bp!(a3, p5, 130, 85, now - 4.hours)

puts "Seeded: Accounts=#{Account.count}, Patients=#{Patient.count}, Obs=#{Observation.count}"
