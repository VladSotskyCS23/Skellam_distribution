require 'flammarion'
require 'distribution'
require 'histogram/array'
require 'csv'

module Flammarion
  class Engraving
    def get_export_save_path
      if Gem.win_platform?
        `powershell "Add-Type -AssemblyName System.windows.forms|Out-Null;$f=New-Object System.Windows.Forms.SaveFileDialog;$f.InitialDirectory='%cd%';$f.Filter='Comma Separated Values|*.csv';$f.showHelp=$true;$f.ShowDialog()|Out-Null;$f.FileName"`.strip
      else
        `zenity --file-selection --filename=Export.csv --save --confirm-overwrite`.strip
      end
    end
  end
end

def show_generate_button(button)
  return button.hide if @mu_1.nil? || @mu_1 <= 0
  return button.hide if @mu_2.nil? || @mu_2 <= 0
  return button.hide if @size.nil? || @size <= 0

  button.show
end

f = Flammarion::Engraving.new
f.title "Vlad Course Work - Skellam Distribution"

graph = f.subpane('Graph')
controls = f.pane('Controls')
controls.orientation = :vertical

inputs = controls.subpane('Inputs')


inputs.input('μ₁') do |input|
  f.status('')
  @mu_1 = input['text'].to_f if !!Float(input['text'])

  f.status('μ₁ must be greater than 0!') if @mu_1 <= 0
  show_generate_button(@generate_pane)
rescue TypeError
  f.status('Write μ₁ as floating number!')
end

inputs.input('μ₂') do |input|
  f.status('')
  @mu_2 = input['text'].to_f if !!Float(input['text'])

  f.status('μ₂ must be greater than 0!') if @mu_2 <= 0
  show_generate_button(@generate_pane)
rescue TypeError
  f.status('Write μ₂ as floating number!')
end

inputs.input('size') do |input|
  f.status('')
  @size = input['text'].to_i if !!Integer(input['text'])

  f.status('size must be greater than 0!') if @size <= 0
  show_generate_button(@generate_pane)
rescue TypeError
  f.status('Write size as integer number!')
end

buttons = controls.subpane('Buttons')
@instruction_button = buttons.button('Instruction') do
  f.alert("Для того, шоб сгенерувати графік випадкових величин за росподілом Скеллама вам потрібно:\n\n\nа)Ввести очікуванні значення(μ1,μ2, які > 0)\n\nб)Ввести size(очікуєму кількість значеннь)\n\nв)Натиснути 'Generate'\n\n Для Експорту в Ексель натисніть'Export'\n\n\n\n   автор:Соцький В.І.")
end

@generate_pane = buttons.subpane('generate')
@generate_pane.hide
@generate_button = @generate_pane.button('Generate') do
  f.status('')
  mu_1_poisson = []
  @size.times { mu_1_poisson << Distribution::Poisson.rng(@mu_1) }

  mu_2_poisson = []
  @size.times { mu_2_poisson << Distribution::Poisson.rng(@mu_2) }

  @data = mu_1_poisson.map.with_index { |mu_1, index| mu_1 - mu_2_poisson[index] }

  (bins, freqs) = @data.histogram(10)
  freqs = freqs.map { |freqs| freqs / @size }

  graph.clear
  graph.plot({ x: bins, y: freqs })

  @export_pane.show

  prb = 1 / @size
  mu_real = @data.inject { |sum, n| sum + @size * prb }

  f.status("μ calculated: #{@mu_1 - @mu_2} | μ real: #{mu_real.to_f}")
end

@export_pane = buttons.subpane('export')
@export_pane.hide
@export_button = @export_pane.button('Export') do
  path_to_save = f.get_export_save_path

  CSV.open(path_to_save, "w") do |csv|
    @data.each { |row| csv << [row] }
  end
end

f.wait_until_closed
