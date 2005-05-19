"""
Implementation of the XDG Recent File Storage Specification Version 0.2
http://standards.freedesktop.org/recent-file-spec
"""

import xml.dom.minidom, xml.sax.saxutils
import os, time, fcntl
from xdg.Exceptions import *

class RecentFiles:
	RecentFiles = []
	filename = ""

	def parse(self, file = ""):
		if not file:
			file = os.path.join(os.getenv("HOME"), ".recently-used")

		try:
			doc = xml.dom.minidom.parse(file)
		except IOError:
			raise ParsingError('File not found', file)
		except xml.parsers.expat.ExpatError:
			raise ParsingError('Not a valid .menu file', file)

		self.filename = file

		for child in doc.childNodes:
			if child.nodeType == xml.dom.Node.ELEMENT_NODE:
				if child.tagName == "RecentFiles":
					for recent in child.childNodes:
						if recent.nodeType == xml.dom.Node.ELEMENT_NODE:	
							if recent.tagName == "RecentItem":
								self.__parseRecentItem(recent)

		self.sort()

	def __parseRecentItem(self, item):
		recent = RecentFile()
		self.RecentFiles.append(recent)

		for attribute in item.childNodes:
			if attribute.nodeType == xml.dom.Node.ELEMENT_NODE:
				if attribute.tagName == "URI":
					recent.URI = attribute.childNodes[0].nodeValue
				elif attribute.tagName == "Mime-Type":
					recent.MimeType = attribute.childNodes[0].nodeValue
				elif attribute.tagName == "Timestamp":
					recent.Timestamp = attribute.childNodes[0].nodeValue
				elif attribute.tagName == "Private":
					recent.Prviate = True
				elif attribute.tagName == "Groups":

					for group in attribute.childNodes:
						if group.nodeType == xml.dom.Node.ELEMENT_NODE:
							if group.tagName == "Group":
								recent.Groups.append(group.childNodes[0].nodeValue)

	def write(self, file = ""):
		if not file and not self.filename:
			raise ParsingError('File not found', file)
		elif not file:
			file = self.filename

		f = open(file, "w")
		fcntl.lockf(f, fcntl.LOCK_EX)
		f.write('<?xml version="1.0"?>\n')
		f.write("<RecentFiles>\n")

		for r in self.RecentFiles:
			f.write("  <RecentItem>\n")
			f.write("    <URI>%s</URI>\n" % xml.sax.saxutils.escape(r.URI))
			f.write("    <Mime-Type>%s</Mime-Type>\n" % r.MimeType)
			f.write("    <Timestamp>%s</Timestamp>\n" % r.Timestamp)
			if r.Private == True:
				f.write("    <Private/>\n")
			if len(r.Groups) > 0:
				f.write("    <Groups>\n")
				for group in r.Groups:
					f.write("      <Group>%s</Group>\n" % group)
				f.write("    </Groups>\n")
			f.write("  </RecentItem>\n")

		f.write("</RecentFiles>\n")
		fcntl.lockf(f, fcntl.LOCK_UN)
		f.close()

	def getFiles(self, mimetypes = None, groups = None, limit = 0):
		tmp = []
		i = 0
		for file in self.RecentFiles:
			if groups:
				for group in groups:
					if group in file.Groups:
						tmp.append(file)
						i += 1
			elif mimetypes:
				for mimetype in mimetypes:
					if mimetype == file.MimeType:
						tmp.append(file)
						i += 1
			else:
				if file.Private == False:
					tmp.append(file)
					i += 1
			if limit != 0 and i == limit:
				break

		return tmp

	def addFile(self, file, mimetype, groups = None, private = False):
		# check if entry already there
		if file in self.RecentFiles:
			index = self.RecentFiles.index(file)
			recent = self.RecentFiles[index]
		else:
			# delete if more then 500 files
			if len(self.RecentFiles) == 500:
				self.RecentFiles.pop()
			# add entry
			recent = RecentFile()
			self.RecentFiles.append(recent)

		recent.URI = file
		recent.MimeType = mimetype
		recent.Timestamp = int(time.time())
		recent.Private = private
		recent.Groups = groups

		self.sort()

	def deleteFile(self, file):
		if file in self.RecentFiles:
			self.RecentFiles.remove(file)

	def sort(self):
		self.RecentFiles.sort()
		self.RecentFiles.reverse()


class RecentFile:
	def __init__(self):
		self.URI = ""
		self.MimeType = ""
		self.Timestamp = ""
		self.Private = False
		self.Groups = []

	def __cmp__(self, other):
		return cmp(self.Timestamp, other.Timestamp)

	def __eq__(self, other):
		if self.URI == str(other):
			return True
		else:
			return False

	def __str__(self):
		return self.URI