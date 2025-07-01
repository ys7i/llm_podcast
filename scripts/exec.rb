# frozen_string_literal: true

require 'dotenv'
require_relative '../text_file_to_speech'

Dotenv.load

converter = TextToSpeechConverter.new

# 入力ファイルを指定して変換を実行
input_file = 'sample.txt'

converter.convert_file(input_file)
