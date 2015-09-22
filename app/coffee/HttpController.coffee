logger = require "logger-sharelatex"
Errors = require "./Errors"
FilestoreHandler = require './FilestoreHandler'
CsvSniffer = require './CsvSniffer'
metrics = require 'metrics-sharelatex'

module.exports = HttpController =

	previewText: (req, res, next = (error) ->) ->
		file_url = req.query.fileUrl
		if !file_url?
			logger.log "no fileUrl query parameter supplied"
			return res.status(400).send("required query param 'fileUrl' missing")
		logger.log file_url: file_url, "Generating preview for file"
		metrics.inc "getPreview"
		FilestoreHandler.getSample file_url, (err, sample) ->
			if err?
				if err instanceof Errors.NotFoundError
					return res.sendStatus 404
				else
					return next(err)
			logger.log file_url: file_url, 'sending preview to client'
			res.setHeader "Content-Type", "application/json"
			res.status(200).send({source: file_url, data: sample.data, truncated: sample.truncated})

	previewCsv: (req, res, next = (error) ->) ->
		file_url = req.query.fileUrl
		if !file_url?
			logger.log "no fileUrl query parameter supplied"
			return res.status(400).send("required query param 'fileUrl' missing")
		logger.log file_url: file_url, "Generating preview for csv file"
		metrics.inc "getPreviewCsv"
		FilestoreHandler.getSample file_url, (err, sample) ->
			if err?
				if err instanceof Errors.NotFoundError
					return res.sendStatus 404
				else
					return next(err)
			logger.log file_url: file_url, 'sniffing csv sample'
			CsvSniffer.sniff sample.data, (err, csv_details) ->
				if err?
					logger.log file_url: file_url, error_message: err.message, "failed to sniff csv sample"
					return next(err)
				res.setHeader "Content-Type", "application/json"
				res.status(200).send(HttpController._build_csv_preview(file_url, csv_details, sample.truncated))

	_build_csv_preview: (file_url, csv_details, truncated) ->
		source: file_url,
		rows: csv_details.records,
		delimiter: csv_details.delimiter,
		quoteChar: csv_details.quoteChar,
		newlineStr: csv_details.newlineStr,
		types: csv_details.types,
		labels: csv_details.labels
		truncated: truncated
