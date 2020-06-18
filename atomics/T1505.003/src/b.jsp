<%--
    Document   : Browser
    Created on : 3/Out/2011, 21:18:45
    Author     : jeanfigueiredo
--%>

<%@page import="java.text.DateFormat"%>
<%--
	jsp File browser 1.2
	Copyright (C) 2003-2006 Boris von Loesch
	This program is free software; you can redistribute it and/or modify it under
	the terms of the GNU General Public License as published by the
	Free Software Foundation; either version 2 of the License, or (at your option)
	any later version.
	This program is distributed in the hope that it will be useful, but
	WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
	FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
	You should have received a copy of the GNU General Public License along with
	this program; if not, write to the
	Free Software Foundation, Inc.,
	59 Temple Place, Suite 330,
	Boston, MA 02111-1307 USA
	- Description: jsp File browser v1.2 -- This JSP program allows remote web-based
				file access and manipulation.  You can copy, create, move and delete files.
				Text files can be edited and groups of files and folders can be downloaded
				as a single zip file that's created on the fly.
	- Credits: Taylor Bastien, David Levine, David Cowan, Lieven Govaerts
--%>
<%@page import="java.util.*,
                java.net.*,
                java.text.*,
                java.util.zip.*,
                java.io.*"
%>
<%!
    //FEATURES
    private static final boolean NATIVE_COMMANDS = true;
	/**
	*If true, all operations (besides upload and native commands)
	*which change something on the file system are permitted
	*/
	private static final boolean READ_ONLY = false;
	//If true, uploads are allowed even if READ_ONLY = true
	private static final boolean ALLOW_UPLOAD = true;

    //Allow browsing and file manipulation only in certain directories
	private static final boolean RESTRICT_BROWSING = true;
    //If true, the user is allowed to browse only in RESTRICT_PATH,
    //if false, the user is allowed to browse all directories besides RESTRICT_PATH
    private static final boolean RESTRICT_WHITELIST = false;
    //Paths, sperated by semicolon
    //private static final String RESTRICT_PATH = "C:\\CODE;E:\\"; //Win32: Case important!!
	private static final String RESTRICT_PATH = "/etc;/var";

    //The refresh time in seconds of the upload monitor window
	private static final int UPLOAD_MONITOR_REFRESH = 2;
	//The number of colums for the edit field
	private static final int EDITFIELD_COLS = 85;
	//The number of rows for the edit field
	private static final int EDITFIELD_ROWS = 30;
	//Open a new window to view a file
	private static final boolean USE_POPUP = true;
	/**
	 * If USE_DIR_PREVIEW = true, then for every directory a tooltip will be
	 * created (hold the mouse over the link) with the first DIR_PREVIEW_NUMBER entries.
	 * This can yield to performance issues. Turn it off, if the directory loads to slow.
	 */
	private static final boolean USE_DIR_PREVIEW = false;
	private static final int DIR_PREVIEW_NUMBER = 10;
	/**
	 * The name of an optional CSS Stylesheet file
	 */
	private static final String CSS_NAME = "Browser.css";
	/**
	 * The compression level for zip file creation (0-9)
	 * 0 = No compression
	 * 1 = Standard compression (Very fast)
	 * ...
	 * 9 = Best compression (Very slow)
	 */
	private static final int COMPRESSION_LEVEL = 1;
	/**
	 * The FORBIDDEN_DRIVES are not displayed on the list. This can be usefull, if the
	 * server runs on a windows platform, to avoid a message box, if you try to access
	 * an empty removable drive (See KNOWN BUGS in Readme.txt).
	 */
	private static final String[] FORBIDDEN_DRIVES = {"a:\\"};

	/**
	 * Command of the shell interpreter and the parameter to run a programm
	 */
	private static final String[] COMMAND_INTERPRETER = {"cmd", "/C"}; // Dos,Windows
	//private static final String[] COMMAND_INTERPRETER = {"/bin/sh","-c"}; 	// Unix

	/**
	 * Max time in ms a process is allowed to run, before it will be terminated
	 */
	private static final long MAX_PROCESS_RUNNING_TIME = 30 * 1000; //30 seconds

	//Button names
	private static final String SAVE_AS_ZIP = "Download selected files as (z)ip";
	private static final String RENAME_FILE = "(R)ename File";
	private static final String DELETE_FILES = "(Del)ete selected files";
	private static final String CREATE_DIR = "Create (D)ir";
	private static final String CREATE_FILE = "(C)reate File";
	private static final String MOVE_FILES = "(M)ove Files";
	private static final String COPY_FILES = "Cop(y) Files";
	private static final String LAUNCH_COMMAND = "(L)aunch external program";
	private static final String UPLOAD_FILES = "Upload";

	//Normally you should not change anything after this line
	//----------------------------------------------------------------------------------
	//Change this to locate the tempfile directory for upload (not longer needed)
	private static String tempdir = ".";
	private static String VERSION_NR = "1.2";
	private static DateFormat dateFormat = DateFormat.getDateTimeInstance();

	public class UplInfo {

		public long totalSize;
		public long currSize;
		public long starttime;
		public boolean aborted;

		public UplInfo() {
			totalSize = 0l;
			currSize = 0l;
			starttime = System.currentTimeMillis();
			aborted = false;
		}

		public UplInfo(int size) {
			totalSize = size;
			currSize = 0;
			starttime = System.currentTimeMillis();
			aborted = false;
		}

		public String getUprate() {
			long time = System.currentTimeMillis() - starttime;
			if (time != 0) {
				long uprate = currSize * 1000 / time;
				return convertFileSize(uprate) + "/s";
			}
			else return "n/a";
		}

		public int getPercent() {
			if (totalSize == 0) return 0;
			else return (int) (currSize * 100 / totalSize);
		}

		public String getTimeElapsed() {
			long time = (System.currentTimeMillis() - starttime) / 1000l;
			if (time - 60l >= 0){
				if (time % 60 >=10) return time / 60 + ":" + (time % 60) + "m";
				else return time / 60 + ":0" + (time % 60) + "m";
			}
			else return time<10 ? "0" + time + "s": time + "s";
		}

		public String getTimeEstimated() {
			if (currSize == 0) return "n/a";
			long time = System.currentTimeMillis() - starttime;
			time = totalSize * time / currSize;
			time /= 1000l;
			if (time - 60l >= 0){
				if (time % 60 >=10) return time / 60 + ":" + (time % 60) + "m";
				else return time / 60 + ":0" + (time % 60) + "m";
			}
			else return time<10 ? "0" + time + "s": time + "s";
		}

	}

	public class FileInfo {

		public String name = null, clientFileName = null, fileContentType = null;
		private byte[] fileContents = null;
		public File file = null;
		public StringBuffer sb = new StringBuffer(100);

		public void setFileContents(byte[] aByteArray) {
			fileContents = new byte[aByteArray.length];
			System.arraycopy(aByteArray, 0, fileContents, 0, aByteArray.length);
		}
	}

	public static class UploadMonitor {

		static Hashtable uploadTable = new Hashtable();

		static void set(String fName, UplInfo info) {
			uploadTable.put(fName, info);
		}

		static void remove(String fName) {
			uploadTable.remove(fName);
		}

		static UplInfo getInfo(String fName) {
			UplInfo info = (UplInfo) uploadTable.get(fName);
			return info;
		}
	}

	// A Class with methods used to process a ServletInputStream
	public class HttpMultiPartParser {

		//private final String lineSeparator = System.getProperty("line.separator", "\n");
		private final int ONE_MB = 1024 * 1;

		public Hashtable processData(ServletInputStream is, String boundary, String saveInDir,
				int clength) throws IllegalArgumentException, IOException {
			if (is == null) throw new IllegalArgumentException("InputStream");
			if (boundary == null || boundary.trim().length() < 1) throw new IllegalArgumentException(
					"\"" + boundary + "\" is an illegal boundary indicator");
			boundary = "--" + boundary;
			StringTokenizer stLine = null, stFields = null;
			FileInfo fileInfo = null;
			Hashtable dataTable = new Hashtable(5);
			String line = null, field = null, paramName = null;
			boolean saveFiles = (saveInDir != null && saveInDir.trim().length() > 0);
			boolean isFile = false;
			if (saveFiles) { // Create the required directory (including parent dirs)
				File f = new File(saveInDir);
				f.mkdirs();
			}
			line = getLine(is);
			if (line == null || !line.startsWith(boundary)) throw new IOException(
					"Boundary not found; boundary = " + boundary + ", line = " + line);
			while (line != null) {
				if (line == null || !line.startsWith(boundary)) return dataTable;
				line = getLine(is);
				if (line == null) return dataTable;
				stLine = new StringTokenizer(line, ";\r\n");
				if (stLine.countTokens() < 2) throw new IllegalArgumentException(
						"Bad data in second line");
				line = stLine.nextToken().toLowerCase();
				if (line.indexOf("form-data") < 0) throw new IllegalArgumentException(
						"Bad data in second line");
				stFields = new StringTokenizer(stLine.nextToken(), "=\"");
				if (stFields.countTokens() < 2) throw new IllegalArgumentException(
						"Bad data in second line");
				fileInfo = new FileInfo();
				stFields.nextToken();
				paramName = stFields.nextToken();
				isFile = false;
				if (stLine.hasMoreTokens()) {
					field = stLine.nextToken();
					stFields = new StringTokenizer(field, "=\"");
					if (stFields.countTokens() > 1) {
						if (stFields.nextToken().trim().equalsIgnoreCase("filename")) {
							fileInfo.name = paramName;
							String value = stFields.nextToken();
							if (value != null && value.trim().length() > 0) {
								fileInfo.clientFileName = value;
								isFile = true;
							}
							else {
								line = getLine(is); // Skip "Content-Type:" line
								line = getLine(is); // Skip blank line
								line = getLine(is); // Skip blank line
								line = getLine(is); // Position to boundary line
								continue;
							}
						}
					}
					else if (field.toLowerCase().indexOf("filename") >= 0) {
						line = getLine(is); // Skip "Content-Type:" line
						line = getLine(is); // Skip blank line
						line = getLine(is); // Skip blank line
						line = getLine(is); // Position to boundary line
						continue;
					}
				}
				boolean skipBlankLine = true;
				if (isFile) {
					line = getLine(is);
					if (line == null) return dataTable;
					if (line.trim().length() < 1) skipBlankLine = false;
					else {
						stLine = new StringTokenizer(line, ": ");
						if (stLine.countTokens() < 2) throw new IllegalArgumentException(
								"Bad data in third line");
						stLine.nextToken(); // Content-Type
						fileInfo.fileContentType = stLine.nextToken();
					}
				}
				if (skipBlankLine) {
					line = getLine(is);
					if (line == null) return dataTable;
				}
				if (!isFile) {
					line = getLine(is);
					if (line == null) return dataTable;
					dataTable.put(paramName, line);
					// If parameter is dir, change saveInDir to dir
					if (paramName.equals("dir")) saveInDir = line;
					line = getLine(is);
					continue;
				}
				try {
					UplInfo uplInfo = new UplInfo(clength);
					UploadMonitor.set(fileInfo.clientFileName, uplInfo);
					OutputStream os = null;
					String path = null;
					if (saveFiles) os = new FileOutputStream(path = getFileName(saveInDir,
							fileInfo.clientFileName));
					else os = new ByteArrayOutputStream(ONE_MB);
					boolean readingContent = true;
					byte previousLine[] = new byte[2 * ONE_MB];
					byte temp[] = null;
					byte currentLine[] = new byte[2 * ONE_MB];
					int read, read3;
					if ((read = is.readLine(previousLine, 0, previousLine.length)) == -1) {
						line = null;
						break;
					}
					while (readingContent) {
						if ((read3 = is.readLine(currentLine, 0, currentLine.length)) == -1) {
							line = null;
							uplInfo.aborted = true;
							break;
						}
						if (compareBoundary(boundary, currentLine)) {
							os.write(previousLine, 0, read - 2);
							line = new String(currentLine, 0, read3);
							break;
						}
						else {
							os.write(previousLine, 0, read);
							uplInfo.currSize += read;
							temp = currentLine;
							currentLine = previousLine;
							previousLine = temp;
							read = read3;
						}//end else
					}//end while
					os.flush();
					os.close();
					if (!saveFiles) {
						ByteArrayOutputStream baos = (ByteArrayOutputStream) os;
						fileInfo.setFileContents(baos.toByteArray());
					}
					else fileInfo.file = new File(path);
					dataTable.put(paramName, fileInfo);
					uplInfo.currSize = uplInfo.totalSize;
				}//end try
				catch (IOException e) {
					throw e;
				}
			}
			return dataTable;
		}

		/**
		 * Compares boundary string to byte array
		 */
		private boolean compareBoundary(String boundary, byte ba[]) {
			if (boundary == null || ba == null) return false;
			for (int i = 0; i < boundary.length(); i++)
				if ((byte) boundary.charAt(i) != ba[i]) return false;
			return true;
		}

		/** Convenience method to read HTTP header lines */
		private synchronized String getLine(ServletInputStream sis) throws IOException {
			byte b[] = new byte[1024];
			int read = sis.readLine(b, 0, b.length), index;
			String line = null;
			if (read != -1) {
				line = new String(b, 0, read);
				if ((index = line.indexOf('\n')) >= 0) line = line.substring(0, index - 1);
			}
			return line;
		}

		public String getFileName(String dir, String fileName) throws IllegalArgumentException {
			String path = null;
			if (dir == null || fileName == null) throw new IllegalArgumentException(
					"dir or fileName is null");
			int index = fileName.lastIndexOf('/');
			String name = null;
			if (index >= 0) name = fileName.substring(index + 1);
			else name = fileName;
			index = name.lastIndexOf('\\');
			if (index >= 0) fileName = name.substring(index + 1);
			path = dir + File.separator + fileName;
			if (File.separatorChar == '/') return path.replace('\\', File.separatorChar);
			else return path.replace('/', File.separatorChar);
		}
	} //End of class HttpMultiPartParser

	/**
	 * This class is a comparator to sort the filenames and dirs
	 */
	class FileComp implements Comparator {

		int mode;
		int sign;

		FileComp() {
			this.mode = 1;
			this.sign = 1;
		}

		/**
		 * @param mode sort by 1=Filename, 2=Size, 3=Date, 4=Type
		 * The default sorting method is by Name
		 * Negative mode means descending sort
		 */
		FileComp(int mode) {
			if (mode < 0) {
				this.mode = -mode;
				sign = -1;
			}
			else {
				this.mode = mode;
				this.sign = 1;
			}
		}

		public int compare(Object o1, Object o2) {
			File f1 = (File) o1;
			File f2 = (File) o2;
			if (f1.isDirectory()) {
				if (f2.isDirectory()) {
					switch (mode) {
					//Filename or Type
					case 1:
					case 4:
						return sign
								* f1.getAbsolutePath().toUpperCase().compareTo(
										f2.getAbsolutePath().toUpperCase());
					//Filesize
					case 2:
						return sign * (new Long(f1.length()).compareTo(new Long(f2.length())));
					//Date
					case 3:
						return sign
								* (new Long(f1.lastModified())
										.compareTo(new Long(f2.lastModified())));
					default:
						return 1;
					}
				}
				else return -1;
			}
			else if (f2.isDirectory()) return 1;
			else {
				switch (mode) {
				case 1:
					return sign
							* f1.getAbsolutePath().toUpperCase().compareTo(
									f2.getAbsolutePath().toUpperCase());
				case 2:
					return sign * (new Long(f1.length()).compareTo(new Long(f2.length())));
				case 3:
					return sign
							* (new Long(f1.lastModified()).compareTo(new Long(f2.lastModified())));
				case 4: { // Sort by extension
					int tempIndexf1 = f1.getAbsolutePath().lastIndexOf('.');
					int tempIndexf2 = f2.getAbsolutePath().lastIndexOf('.');
					if ((tempIndexf1 == -1) && (tempIndexf2 == -1)) { // Neither have an extension
						return sign
								* f1.getAbsolutePath().toUpperCase().compareTo(
										f2.getAbsolutePath().toUpperCase());
					}
					// f1 has no extension
					else if (tempIndexf1 == -1) return -sign;
					// f2 has no extension
					else if (tempIndexf2 == -1) return sign;
					// Both have an extension
					else {
						String tempEndf1 = f1.getAbsolutePath().toUpperCase()
								.substring(tempIndexf1);
						String tempEndf2 = f2.getAbsolutePath().toUpperCase()
								.substring(tempIndexf2);
						return sign * tempEndf1.compareTo(tempEndf2);
					}
				}
				default:
					return 1;
				}
			}
		}
	}

	/**
	 * Wrapperclass to wrap an OutputStream around a Writer
	 */
	class Writer2Stream extends OutputStream {

		Writer out;

		Writer2Stream(Writer w) {
			super();
			out = w;
		}

		public void write(int i) throws IOException {
			out.write(i);
		}

		public void write(byte[] b) throws IOException {
			for (int i = 0; i < b.length; i++) {
				int n = b[i];
				//Convert byte to ubyte
				n = ((n >>> 4) & 0xF) * 16 + (n & 0xF);
				out.write(n);
			}
		}

		public void write(byte[] b, int off, int len) throws IOException {
			for (int i = off; i < off + len; i++) {
				int n = b[i];
				n = ((n >>> 4) & 0xF) * 16 + (n & 0xF);
				out.write(n);
			}
		}
	} //End of class Writer2Stream

	static Vector expandFileList(String[] files, boolean inclDirs) {
		Vector v = new Vector();
		if (files == null) return v;
		for (int i = 0; i < files.length; i++)
			v.add(new File(URLDecoder.decode(files[i])));
		for (int i = 0; i < v.size(); i++) {
			File f = (File) v.get(i);
			if (f.isDirectory()) {
				File[] fs = f.listFiles();
				for (int n = 0; n < fs.length; n++)
					v.add(fs[n]);
				if (!inclDirs) {
					v.remove(i);
					i--;
				}
			}
		}
		return v;
	}

	/**
	 * Method to build an absolute path
	 * @param dir the root dir
	 * @param name the name of the new directory
	 * @return if name is an absolute directory, returns name, else returns dir+name
	 */
	static String getDir(String dir, String name) {
		if (!dir.endsWith(File.separator)) dir = dir + File.separator;
		File mv = new File(name);
		String new_dir = null;
		if (!mv.isAbsolute()) {
			new_dir = dir + name;
		}
		else new_dir = name;
		return new_dir;
	}

	/**
	 * This Method converts a byte size in a kbytes or Mbytes size, depending on the size
	 *     @param size The size in bytes
	 *     @return String with size and unit
	 */
	static String convertFileSize(long size) {
		int divisor = 1;
		String unit = "bytes";
		if (size >= 1024 * 1024) {
			divisor = 1024 * 1024;
			unit = "MB";
		}
		else if (size >= 1024) {
			divisor = 1024;
			unit = "KB";
		}
		if (divisor == 1) return size / divisor + " " + unit;
		String aftercomma = "" + 100 * (size % divisor) / divisor;
		if (aftercomma.length() == 1) aftercomma = "0" + aftercomma;
		return size / divisor + "." + aftercomma + " " + unit;
	}

	/**
	 * Copies all data from in to out
	 * 	@param in the input stream
	 *	@param out the output stream
	 *	@param buffer copy buffer
	 */
	static void copyStreams(InputStream in, OutputStream out, byte[] buffer) throws IOException {
		copyStreamsWithoutClose(in, out, buffer);
		in.close();
		out.close();
	}

	/**
	 * Copies all data from in to out
	 * 	@param in the input stream
	 *	@param out the output stream
	 *	@param buffer copy buffer
	 */
	static void copyStreamsWithoutClose(InputStream in, OutputStream out, byte[] buffer)
			throws IOException {
		int b;
		while ((b = in.read(buffer)) != -1)
			out.write(buffer, 0, b);
	}

	/**
	 * Returns the Mime Type of the file, depending on the extension of the filename
	 */
	static String getMimeType(String fName) {
		fName = fName.toLowerCase();
		if (fName.endsWith(".jpg") || fName.endsWith(".jpeg") || fName.endsWith(".jpe")) return "image/jpeg";
		else if (fName.endsWith(".gif")) return "image/gif";
		else if (fName.endsWith(".pdf")) return "application/pdf";
		else if (fName.endsWith(".htm") || fName.endsWith(".html") || fName.endsWith(".shtml")) return "text/html";
		else if (fName.endsWith(".avi")) return "video/x-msvideo";
		else if (fName.endsWith(".mov") || fName.endsWith(".qt")) return "video/quicktime";
		else if (fName.endsWith(".mpg") || fName.endsWith(".mpeg") || fName.endsWith(".mpe")) return "video/mpeg";
		else if (fName.endsWith(".zip")) return "application/zip";
		else if (fName.endsWith(".tiff") || fName.endsWith(".tif")) return "image/tiff";
		else if (fName.endsWith(".rtf")) return "application/rtf";
		else if (fName.endsWith(".mid") || fName.endsWith(".midi")) return "audio/x-midi";
		else if (fName.endsWith(".xl") || fName.endsWith(".xls") || fName.endsWith(".xlv")
				|| fName.endsWith(".xla") || fName.endsWith(".xlb") || fName.endsWith(".xlt")
				|| fName.endsWith(".xlm") || fName.endsWith(".xlk")) return "application/excel";
		else if (fName.endsWith(".doc") || fName.endsWith(".dot")) return "application/msword";
		else if (fName.endsWith(".png")) return "image/png";
		else if (fName.endsWith(".xml")) return "text/xml";
		else if (fName.endsWith(".svg")) return "image/svg+xml";
		else if (fName.endsWith(".mp3")) return "audio/mp3";
		else if (fName.endsWith(".ogg")) return "audio/ogg";
		else return "text/plain";
	}

	/**
	 * Converts some important chars (int) to the corresponding html string
	 */
	static String conv2Html(int i) {
		if (i == '&') return "&amp;";
		else if (i == '<') return "&lt;";
		else if (i == '>') return "&gt;";
		else if (i == '"') return "&quot;";
		else return "" + (char) i;
	}

	/**
	 * Converts a normal string to a html conform string
	 */
	static String conv2Html(String st) {
		StringBuffer buf = new StringBuffer();
		for (int i = 0; i < st.length(); i++) {
			buf.append(conv2Html(st.charAt(i)));
		}
		return buf.toString();
	}

	/**
	 * Starts a native process on the server
	 * 	@param command the command to start the process
	 *	@param dir the dir in which the process starts
	 */
	static String startProcess(String command, String dir) throws IOException {
		StringBuffer ret = new StringBuffer();
		String[] comm = new String[3];
		comm[0] = COMMAND_INTERPRETER[0];
		comm[1] = COMMAND_INTERPRETER[1];
		comm[2] = command;
		long start = System.currentTimeMillis();
		try {
			//Start process
			Process ls_proc = Runtime.getRuntime().exec(comm, null, new File(dir));
			//Get input and error streams
			BufferedInputStream ls_in = new BufferedInputStream(ls_proc.getInputStream());
			BufferedInputStream ls_err = new BufferedInputStream(ls_proc.getErrorStream());
			boolean end = false;
			while (!end) {
				int c = 0;
				while ((ls_err.available() > 0) && (++c <= 1000)) {
					ret.append(conv2Html(ls_err.read()));
				}
				c = 0;
				while ((ls_in.available() > 0) && (++c <= 1000)) {
					ret.append(conv2Html(ls_in.read()));
				}
				try {
					ls_proc.exitValue();
					//if the process has not finished, an exception is thrown
					//else
					while (ls_err.available() > 0)
						ret.append(conv2Html(ls_err.read()));
					while (ls_in.available() > 0)
						ret.append(conv2Html(ls_in.read()));
					end = true;
				}
				catch (IllegalThreadStateException ex) {
					//Process is running
				}
				//The process is not allowed to run longer than given time.
				if (System.currentTimeMillis() - start > MAX_PROCESS_RUNNING_TIME) {
					ls_proc.destroy();
					end = true;
					ret.append("!!!! Process has timed out, destroyed !!!!!");
				}
				try {
					Thread.sleep(50);
				}
				catch (InterruptedException ie) {}
			}
		}
		catch (IOException e) {
			ret.append("Error: " + e);
		}
		return ret.toString();
	}

	/**
	 * Converts a dir string to a linked dir string
	 * 	@param dir the directory string (e.g. /usr/local/httpd)
	 *	@param browserLink web-path to Browser.jsp
	 */
	static String dir2linkdir(String dir, String browserLink, int sortMode) {
		File f = new File(dir);
		StringBuffer buf = new StringBuffer();
		while (f.getParentFile() != null) {
			if (f.canRead()) {
				String encPath = URLEncoder.encode(f.getAbsolutePath());
				buf.insert(0, "<a href=\"" + browserLink + "?sort=" + sortMode + "&amp;dir="
						+ encPath + "\">" + conv2Html(f.getName()) + File.separator + "</a>");
			}
			else buf.insert(0, conv2Html(f.getName()) + File.separator);
			f = f.getParentFile();
		}
		if (f.canRead()) {
			String encPath = URLEncoder.encode(f.getAbsolutePath());
			buf.insert(0, "<a href=\"" + browserLink + "?sort=" + sortMode + "&amp;dir=" + encPath
					+ "\">" + conv2Html(f.getAbsolutePath()) + "</a>");
		}
		else buf.insert(0, f.getAbsolutePath());
		return buf.toString();
	}

	/**
	 *	Returns true if the given filename tends towards a packed file
	 */
	static boolean isPacked(String name, boolean gz) {
		return (name.toLowerCase().endsWith(".zip") || name.toLowerCase().endsWith(".jar")
				|| (gz && name.toLowerCase().endsWith(".gz")) || name.toLowerCase()
				.endsWith(".war"));
	}

	/**
	 *	If RESTRICT_BROWSING = true this method checks, whether the path is allowed or not
	 */
	static boolean isAllowed(File path, boolean write) throws IOException{
		if (READ_ONLY && write) return false;
		if (RESTRICT_BROWSING) {
            StringTokenizer stk = new StringTokenizer(RESTRICT_PATH, ";");
            while (stk.hasMoreTokens()){
			    if (path!=null && path.getCanonicalPath().startsWith(stk.nextToken()))
                    return RESTRICT_WHITELIST;
            }
            return !RESTRICT_WHITELIST;
		}
		else return true;
	}

	//---------------------------------------------------------------------------------------------------------------

	%>
<%
		//Get the current browsing directory
		request.setAttribute("dir", request.getParameter("dir"));
		// The browser_name variable is used to keep track of the URI
		// of the jsp file itself.  It is used in all link-backs.
		final String browser_name = request.getRequestURI();
		final String FOL_IMG = "";
		boolean nohtml = false;
		boolean dir_view = true;
		//Get Javascript
		if (request.getParameter("Javascript") != null) {
			dir_view = false;
			nohtml = true;
			//Tell the browser that it should cache the javascript
			response.setHeader("Cache-Control", "public");
			Date now = new Date();
			SimpleDateFormat sdf = new SimpleDateFormat("EEE, d MMM yyyy HH:mm:ss z", Locale.US);
			response.setHeader("Expires", sdf.format(new Date(now.getTime() + 1000 * 60 * 60 * 24*2)));
			response.setHeader("Content-Type", "text/javascript");
			%>
			<%// This section contains the Javascript used for interface elements %>
			var check = false;
			<%// Disables the checkbox feature %>
			function dis(){check = true;}

			var DOM = 0, MS = 0, OP = 0, b = 0;
			<%// Determine the browser type %>
			function CheckBrowser(){
				if (b == 0){
					if (window.opera) OP = 1;
					// Moz or Netscape
					if(document.getElementById) DOM = 1;
					// Micro$oft
					if(document.all && !OP) MS = 1;
					b = 1;
				}
			}
			<%// Allows the whole row to be selected %>
			function selrow (element, i){
				var erst;
				CheckBrowser();
				if ((OP==1)||(MS==1)) erst = element.firstChild.firstChild;
				else if (DOM==1) erst = element.firstChild.nextSibling.firstChild;
				<%// MouseIn %>
				if (i==0){
					if (erst.checked == true) element.className='mousechecked';
					else element.className='mousein';
				}
				<%// MouseOut %>
				else if (i==1){
					if (erst.checked == true) element.className='checked';
					else element.className='mouseout';
				}
				<%    // MouseClick %>
				else if ((i==2)&&(!check)){
					if (erst.checked==true) element.className='mousein';
					else element.className='mousechecked';
					erst.click();
				}
				else check=false;
			}
			<%// Filter files and dirs in FileList%>
			function filter (begriff){
				var suche = begriff.value.toLowerCase();
				var table = document.getElementById("filetable");
				var ele;
				for (var r = 1; r < table.rows.length; r++){
					ele = table.rows[r].cells[1].innerHTML.replace(/<[^>]+>/g,"");
					if (ele.toLowerCase().indexOf(suche)>=0 )
						table.rows[r].style.display = '';
					else table.rows[r].style.display = 'none';
		      	}
			}
			<%//(De)select all checkboxes%>
			function AllFiles(){
				for(var x=0;x < document.FileList.elements.length;x++){
					var y = document.FileList.elements[x];
					var ytr = y.parentNode.parentNode;
					var check = document.FileList.selall.checked;
					if(y.name == 'selfile' && ytr.style.display != 'none'){
						if (y.disabled != true){
							y.checked = check;
							if (y.checked == true) ytr.className = 'checked';
							else ytr.className = 'mouseout';
						}
					}
				}
			}

			function shortKeyHandler(_event){
				if (!_event) _event = window.event;
				if (_event.which) {
					keycode = _event.which;
				} else if (_event.keyCode) {
					keycode = _event.keyCode;
				}
				var t = document.getElementById("text_Dir");
				//z
				if (keycode == 122){
					document.getElementById("but_Zip").click();
				}
				//r, F2
				else if (keycode == 113 || keycode == 114){
					var path = prompt("Please enter new filename", "");
					if (path == null) return;
					t.value = path;
					document.getElementById("but_Ren").click();
				}
				//c
				else if (keycode == 99){
					var path = prompt("Please enter filename", "");
					if (path == null) return;
					t.value = path;
					document.getElementById("but_NFi").click();
				}
				//d
				else if (keycode == 100){
					var path = prompt("Please enter directory name", "");
					if (path == null) return;
					t.value = path;
					document.getElementById("but_NDi").click();
				}
				//m
				else if (keycode == 109){
					var path = prompt("Please enter move destination", "");
					if (path == null) return;
					t.value = path;
					document.getElementById("but_Mov").click();
				}
				//y
				else if (keycode == 121){
					var path = prompt("Please enter copy destination", "");
					if (path == null) return;
					t.value = path;
					document.getElementById("but_Cop").click();
				}
				//l
				else if (keycode == 108){
					document.getElementById("but_Lau").click();
				}
				//Del
				else if (keycode == 46){
					document.getElementById("but_Del").click();
				}
			}

			function popUp(URL){
				fname = document.getElementsByName("myFile")[0].value;
				if (fname != "")
					window.open(URL+"?first&uplMonitor="+encodeURIComponent(fname),"","width=400,height=150,resizable=yes,depend=yes")
			}

			document.onkeypress = shortKeyHandler;
<% 		}
		// View file
		else if (request.getParameter("file") != null) {
            File f = new File(request.getParameter("file"));
            if (!isAllowed(f, false)) {
                request.setAttribute("dir", f.getParent());
                request.setAttribute("error", "You are not allowed to access "+f.getAbsolutePath());
            }
            else if (f.exists() && f.canRead()) {
                if (isPacked(f.getName(), false)) {
                    //If zipFile, do nothing here
                }
                else{
                    String mimeType = getMimeType(f.getName());
                    response.setContentType(mimeType);
                    if (mimeType.equals("text/plain")) response.setHeader(
                            "Content-Disposition", "inline;filename=\"temp.txt\"");
                    else response.setHeader("Content-Disposition", "inline;filename=\""
                            + f.getName() + "\"");
                    BufferedInputStream fileInput = new BufferedInputStream(new FileInputStream(f));
                    byte buffer[] = new byte[8 * 1024];
                    out.clearBuffer();
                    OutputStream out_s = new Writer2Stream(out);
                    copyStreamsWithoutClose(fileInput, out_s, buffer);
                    fileInput.close();
                    out_s.flush();
                    nohtml = true;
                    dir_view = false;
                }
            }
            else {
                request.setAttribute("dir", f.getParent());
                request.setAttribute("error", "File " + f.getAbsolutePath()
                        + " does not exist or is not readable on the server");
            }
		}
		// Download selected files as zip file
		else if ((request.getParameter("Submit") != null)
				&& (request.getParameter("Submit").equals(SAVE_AS_ZIP))) {
			Vector v = expandFileList(request.getParameterValues("selfile"), false);
			//Check if all files in vector are allowed
			String notAllowedFile = null;
			for (int i = 0;i < v.size(); i++){
				File f = (File) v.get(i);
				if (!isAllowed(f, false)){
					notAllowedFile = f.getAbsolutePath();
					break;
				}
			}
			if (notAllowedFile != null){
				request.setAttribute("error", "You are not allowed to access " + notAllowedFile);
			}
			else if (v.size() == 0) {
				request.setAttribute("error", "No files selected");
			}
			else {
				File dir_file = new File("" + request.getAttribute("dir"));
				int dir_l = dir_file.getAbsolutePath().length();
				response.setContentType("application/zip");
				response.setHeader("Content-Disposition", "attachment;filename=\"rename_me.zip\"");
				out.clearBuffer();
				ZipOutputStream zipout = new ZipOutputStream(new Writer2Stream(out));
				zipout.setComment("Created by jsp File Browser v. " + VERSION_NR);
				zipout.setLevel(COMPRESSION_LEVEL);
				for (int i = 0; i < v.size(); i++) {
					File f = (File) v.get(i);
					if (f.canRead()) {
						zipout.putNextEntry(new ZipEntry(f.getAbsolutePath().substring(dir_l + 1)));
						BufferedInputStream fr = new BufferedInputStream(new FileInputStream(f));
						byte buffer[] = new byte[0xffff];
						copyStreamsWithoutClose(fr, zipout, buffer);
						/*					int b;
						 while ((b=fr.read())!=-1) zipout.write(b);*/
						fr.close();
						zipout.closeEntry();
					}
				}
				zipout.finish();
				out.flush();
				nohtml = true;
				dir_view = false;
			}
		}
		// Download file
		else if (request.getParameter("downfile") != null) {
			String filePath = request.getParameter("downfile");
			File f = new File(filePath);
			if (!isAllowed(f, false)){
				request.setAttribute("dir", f.getParent());
				request.setAttribute("error", "You are not allowed to access " + f.getAbsoluteFile());
			}
			else if (f.exists() && f.canRead()) {
				response.setContentType("application/octet-stream");
				response.setHeader("Content-Disposition", "attachment;filename=\"" + f.getName()
						+ "\"");
				response.setContentLength((int) f.length());
				BufferedInputStream fileInput = new BufferedInputStream(new FileInputStream(f));
				byte buffer[] = new byte[8 * 1024];
				out.clearBuffer();
				OutputStream out_s = new Writer2Stream(out);
				copyStreamsWithoutClose(fileInput, out_s, buffer);
				fileInput.close();
				out_s.flush();
				nohtml = true;
				dir_view = false;
			}
			else {
				request.setAttribute("dir", f.getParent());
				request.setAttribute("error", "File " + f.getAbsolutePath()
						+ " does not exist or is not readable on the server");
			}
		}
		if (nohtml) return;
		//else
			// If no parameter is submitted, it will take the path from jsp file browser
			if (request.getAttribute("dir") == null) {
				String path = null;
				if (application.getRealPath(request.getRequestURI()) != null) {
					File f = new File(application.getRealPath(request.getRequestURI())).getParentFile();
					//This is a hack needed for tomcat
					while (f != null && !f.exists())
						f = f.getParentFile();
					if (f != null)
						path = f.getAbsolutePath();
				}
				if (path == null) { // handle the case where we are not in a directory (ex: war file)
					path = new File(".").getAbsolutePath();
				}
				//Check path
                if (!isAllowed(new File(path), false)){
                	//TODO Blacklist
                    if (RESTRICT_PATH.indexOf(";")<0) path = RESTRICT_PATH;
                    else path = RESTRICT_PATH.substring(0, RESTRICT_PATH.indexOf(";"));
                }
				request.setAttribute("dir", path);
			}%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
"http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="content-type" content="text/html; charset=ISO-8859-1">
<meta name="robots" content="noindex">
<meta http-equiv="expires" content="0">
<meta http-equiv="pragma" content="no-cache">
<%
			//If a cssfile exists, it will take it
			String cssPath = null;
			if (application.getRealPath(request.getRequestURI()) != null) cssPath = new File(
					application.getRealPath(request.getRequestURI())).getParent()
					+ File.separator + CSS_NAME;
			if (cssPath == null) cssPath = application.getResource(CSS_NAME).toString();
			if (new File(cssPath).exists()) {
%>
<link rel="stylesheet" type="text/css" href="<%=CSS_NAME%>">
      <%}
			else if (request.getParameter("uplMonitor") == null) {%>
	<style type="text/css">
		input.button {background-color: #c0c0c0; color: #666666;
		border: 1px solid #999999; margin: 5px 1px 5px 1px;}
		input.textfield {margin: 5px 1px 5px 1px;}
		input.button:Hover { color: #444444 }
		table.filelist {background-color:#666666; width:100%; border:0px none #ffffff}
		.formular {margin: 1px; background-color:#ffffff; padding: 1em; border:1px solid #000000;}
		.formular2 {margin: 1px;}
		th { background-color:#c0c0c0 }
		tr.mouseout { background-color:#ffffff; }
		tr.mousein  { background-color:#eeeeee; }
		tr.checked  { background-color:#cccccc }
		tr.mousechecked { background-color:#c0c0c0 }
		td { font-family:Verdana, Arial, Helvetica, sans-serif; font-size: 8pt; color: #666666;}
		td.message { background-color: #FFFF00; color: #000000; text-align:center; font-weight:bold}
		td.error { background-color: #FF0000; color: #000000; text-align:center; font-weight:bold}
		A { text-decoration: none; }
		A:Hover { color : Red; text-decoration : underline; }
		BODY { font-family:Verdana, Arial, Helvetica, sans-serif; font-size: 8pt; color: #666666;}
	</style>
	<%}

        //Check path
        if (!isAllowed(new File((String)request.getAttribute("dir")), false)){
            request.setAttribute("error", "You are not allowed to access " + request.getAttribute("dir"));
        }
		//Upload monitor
		else if (request.getParameter("uplMonitor") != null) {%>
	<style type="text/css">
		BODY { font-family:Verdana, Arial, Helvetica, sans-serif; font-size: 8pt; color: #666666;}
	</style><%
			String fname = request.getParameter("uplMonitor");
			//First opening
			boolean first = false;
			if (request.getParameter("first") != null) first = true;
			UplInfo info = new UplInfo();
			if (!first) {
				info = UploadMonitor.getInfo(fname);
				if (info == null) {
					//Windows
					int posi = fname.lastIndexOf("\\");
					if (posi != -1) info = UploadMonitor.getInfo(fname.substring(posi + 1));
				}
				if (info == null) {
					//Unix
					int posi = fname.lastIndexOf("/");
					if (posi != -1) info = UploadMonitor.getInfo(fname.substring(posi + 1));
				}
			}
			dir_view = false;
			request.setAttribute("dir", null);
			if (info.aborted) {
				UploadMonitor.remove(fname);
				%>
</head>
<body>
<b>Upload of <%=fname%></b><br><br>
Upload aborted.</body>
</html><%
			}
			else if (info.totalSize != info.currSize || info.currSize == 0) {
				%>
<META HTTP-EQUIV="Refresh" CONTENT="<%=UPLOAD_MONITOR_REFRESH%>;URL=<%=browser_name %>?uplMonitor=<%=URLEncoder.encode(fname)%>">
</head>
<body>
<b>Upload of <%=fname%></b><br><br>
<center>
<table height="20px" width="90%" bgcolor="#eeeeee" style="border:1px solid #cccccc"><tr>
<td bgcolor="blue" width="<%=info.getPercent()%>%"></td><td width="<%=100-info.getPercent()%>%"></td>
</tr></table></center>
<%=convertFileSize(info.currSize)%> from <%=convertFileSize(info.totalSize)%>
(<%=info.getPercent()%> %) uploaded (Speed: <%=info.getUprate()%>).<br>
Time: <%=info.getTimeElapsed()%> from <%=info.getTimeEstimated()%>
</body>
</html><%
			}
			else {
				UploadMonitor.remove(fname);
				%>
</head>
<body onload="javascript:window.close()">
<b>Upload of <%=fname%></b><br><br>
Upload finished.
</body>
</html><%
			}
		}
		//Comandwindow
		else if (request.getParameter("command") != null) {
            if (!NATIVE_COMMANDS){
                request.setAttribute("error", "Execution of native commands is not allowed!");
            }
			else if (!"Cancel".equalsIgnoreCase(request.getParameter("Submit"))) {
%>
<title>Launch commands in <%=request.getAttribute("dir")%></title>
</head>
<body><center>
<h2><%=LAUNCH_COMMAND %></h2><br />
<%
				out.println("<form action=\"" + browser_name + "\" method=\"Post\">\n"
						+ "<textarea name=\"text\" wrap=\"off\" cols=\"" + EDITFIELD_COLS
						+ "\" rows=\"" + EDITFIELD_ROWS + "\" readonly>");
				String ret = "";
				if (!request.getParameter("command").equalsIgnoreCase(""))
                    ret = startProcess(
						request.getParameter("command"), (String) request.getAttribute("dir"));
				out.println(ret);
%></textarea>
	<input type="hidden" name="dir" value="<%= request.getAttribute("dir")%>">
	<br /><br />
	<table class="formular">
	<tr><td title="Enter your command">
	Command: <input size="<%=EDITFIELD_COLS-5%>" type="text" name="command" value="">
	</td></tr>
	<tr><td><input class="button" type="Submit" name="Submit" value="Launch">
	<input type="hidden" name="sort" value="<%=request.getParameter("sort")%>">
	<input type="Submit" class="button" name="Submit" value="Cancel"></td></tr>
	</table>
	</form>
	<br />
	<hr>
	<center>
		<small>jsp File Browser version <%= VERSION_NR%> by <a href="http://www.vonloesch.de">www.vonloesch.de</a></small>
	</center>
	</center>
</body>
</html>
<%
				dir_view = false;
				request.setAttribute("dir", null);
			}
		}

		//Click on a filename, special viewer (zip+jar file)
		else if (request.getParameter("file") != null) {
			File f = new File(request.getParameter("file"));
            if (!isAllowed(f, false)){
                request.setAttribute("error", "You are not allowed to access " + f.getAbsolutePath());
            }
			else if (isPacked(f.getName(), false)) {
				//ZipFile
				try {
					ZipFile zf = new ZipFile(f);
					Enumeration entries = zf.entries();
%>
<title><%= f.getAbsolutePath()%></title>
</head>
<body>
	<h2>Content of <%=conv2Html(f.getName())%></h2><br />
	<table class="filelist" cellspacing="1px" cellpadding="0px">
	<th>Name</th><th>Uncompressed size</th><th>Compressed size</th><th>Compr. ratio</th><th>Date</th>
<%
					long size = 0;
					int fileCount = 0;
					while (entries.hasMoreElements()) {
						ZipEntry entry = (ZipEntry) entries.nextElement();
						if (!entry.isDirectory()) {
							fileCount++;
							size += entry.getSize();
							long ratio = 0;
							if (entry.getSize() != 0) ratio = (entry.getCompressedSize() * 100)
									/ entry.getSize();
							out.println("<tr class=\"mouseout\"><td>" + conv2Html(entry.getName())
									+ "</td><td>" + convertFileSize(entry.getSize()) + "</td><td>"
									+ convertFileSize(entry.getCompressedSize()) + "</td><td>"
									+ ratio + "%" + "</td><td>"
									+ dateFormat.format(new Date(entry.getTime())) + "</td></tr>");

						}
					}
					zf.close();
					//No directory view
					dir_view = false;
					request.setAttribute("dir", null);
%>
	</table>
	<p align=center>
	<b><%=convertFileSize(size)%> in <%=fileCount%> files in <%=f.getName()%>. Compression ratio: <%=(f.length() * 100) / size%>%
	</b></p>
</body></html>
<%
				}
				catch (ZipException ex) {
					request.setAttribute("error", "Cannot read " + f.getName()
							+ ", no valid zip file");
				}
				catch (IOException ex) {
					request.setAttribute("error", "Reading of " + f.getName() + " aborted. Error: "
							+ ex);
				}
			}
		}
		// Upload
		else if ((request.getContentType() != null)
				&& (request.getContentType().toLowerCase().startsWith("multipart"))) {
			if (!ALLOW_UPLOAD){
                request.setAttribute("error", "Upload is forbidden!");
            }
			response.setContentType("text/html");
			HttpMultiPartParser parser = new HttpMultiPartParser();
			boolean error = false;
			try {
				int bstart = request.getContentType().lastIndexOf("oundary=");
				String bound = request.getContentType().substring(bstart + 8);
				int clength = request.getContentLength();
				Hashtable ht = parser
						.processData(request.getInputStream(), bound, tempdir, clength);
                if (!isAllowed(new File((String)ht.get("dir")), false)){
                    //This is a hack, cos we are writing to this directory
                	request.setAttribute("error", "You are not allowed to access " + ht.get("dir"));
                    error = true;
                }
				else if (ht.get("myFile") != null) {
					FileInfo fi = (FileInfo) ht.get("myFile");
					File f = fi.file;
					UplInfo info = UploadMonitor.getInfo(fi.clientFileName);
					if (info != null && info.aborted) {
						f.delete();
						request.setAttribute("error", "Upload aborted");
					}
					else {
						// Move file from temp to the right dir
						String path = (String) ht.get("dir");
						if (!path.endsWith(File.separator)) path = path + File.separator;
						if (!f.renameTo(new File(path + f.getName()))) {
							request.setAttribute("error", "Cannot upload file.");
							error = true;
							f.delete();
						}
					}
				}
				else {
					request.setAttribute("error", "No file selected for upload");
					error = true;
				}
				request.setAttribute("dir", (String) ht.get("dir"));
			}
			catch (Exception e) {
				request.setAttribute("error", "Error " + e + ". Upload aborted");
				error = true;
			}
			if (!error) request.setAttribute("message", "File upload correctly finished.");
		}
		// The form to edit a text file
		else if (request.getParameter("editfile") != null) {
			File ef = new File(request.getParameter("editfile"));
            if (!isAllowed(ef, true)){
                request.setAttribute("error", "You are not allowed to access " + ef.getAbsolutePath());
            }
            else{
%>
<title>Edit <%=conv2Html(request.getParameter("editfile"))%></title>
</head>
<body>
<center>
<h2>Edit <%=conv2Html(request.getParameter("editfile"))%></h2><br />
<%
                BufferedReader reader = new BufferedReader(new FileReader(ef));
                String disable = "";
                if (!ef.canWrite()) disable = " readonly";
                out.println("<form action=\"" + browser_name + "\" method=\"Post\">\n"
                        + "<textarea name=\"text\" wrap=\"off\" cols=\"" + EDITFIELD_COLS
                        + "\" rows=\"" + EDITFIELD_ROWS + "\"" + disable + ">");
                String c;
                // Write out the file and check if it is a win or unix file
                int i;
                boolean dos = false;
                boolean cr = false;
                while ((i = reader.read()) >= 0) {
                    out.print(conv2Html(i));
                    if (i == '\r') cr = true;
                    else if (cr && (i == '\n')) dos = true;
                    else cr = false;
                }
                reader.close();
                //No File directory is shown
                request.setAttribute("dir", null);
                dir_view = false;

%></textarea><br /><br />
<table class="formular">
	<input type="hidden" name="nfile" value="<%= request.getParameter("editfile")%>">
	<input type="hidden" name="sort" value="<%=request.getParameter("sort")%>">
		<tr><td colspan="2"><input type="radio" name="lineformat" value="dos" <%= dos?"checked":""%>>Ms-Dos/Windows
		<input type="radio" name="lineformat" value="unix" <%= dos?"":"checked"%>>Unix
		<input type="checkbox" name="Backup" checked>Write backup</td></tr>
		<tr><td title="Enter the new filename"><input type="text" name="new_name" value="<%=ef.getName()%>">
		<input type="Submit" name="Submit" value="Save"></td>
	</form>
	<form action="<%=browser_name%>" method="Post">
	<td align="left">
	<input type="Submit" name="Submit" value="Cancel">
	<input type="hidden" name="nfile" value="<%= request.getParameter("editfile")%>">
	<input type="hidden" name="sort" value="<%=request.getParameter("sort")%>">
	</td>
	</form>
	</tr>
	</table>
	</center>
	<br />
	<hr>
	<center>
		<small>jsp File Browser version <%= VERSION_NR%> by <a href="http://www.vonloesch.de">www.vonloesch.de</a></small>
	</center>
</body>
</html>
<%
            }
		}
		// Save or cancel the edited file
		else if (request.getParameter("nfile") != null) {
			File f = new File(request.getParameter("nfile"));
			if (request.getParameter("Submit").equals("Save")) {
				File new_f = new File(getDir(f.getParent(), request.getParameter("new_name")));
	            if (!isAllowed(new_f, true)){
	                request.setAttribute("error", "You are not allowed to access " + new_f.getAbsolutePath());
	            }
				if (new_f.exists() && new_f.canWrite() && request.getParameter("Backup") != null) {
					File bak = new File(new_f.getAbsolutePath() + ".bak");
					bak.delete();
					new_f.renameTo(bak);
				}
				if (new_f.exists() && !new_f.canWrite()) request.setAttribute("error",
						"Cannot write to " + new_f.getName() + ", file is write protected.");
				else {
					BufferedWriter outs = new BufferedWriter(new FileWriter(new_f));
					StringReader text = new StringReader(request.getParameter("text"));
					int i;
					boolean cr = false;
					String lineend = "\n";
					if (request.getParameter("lineformat").equals("dos")) lineend = "\r\n";
					while ((i = text.read()) >= 0) {
						if (i == '\r') cr = true;
						else if (i == '\n') {
							outs.write(lineend);
							cr = false;
						}
						else if (cr) {
							outs.write(lineend);
							cr = false;
						}
						else {
							outs.write(i);
							cr = false;
						}
					}
					outs.flush();
					outs.close();
				}
			}
			request.setAttribute("dir", f.getParent());
		}
		//Unpack file to the current directory without overwriting
		else if (request.getParameter("unpackfile") != null) {
			File f = new File(request.getParameter("unpackfile"));
			String root = f.getParent();
			request.setAttribute("dir", root);
            if (!isAllowed(new File(root), true)){
                request.setAttribute("error", "You are not allowed to access " + root);
            }
			//Check if file exists
			else if (!f.exists()) {
				request.setAttribute("error", "Cannot unpack " + f.getName()
						+ ", file does not exist");
			}
			//Check if directory is readonly
			else if (!f.getParentFile().canWrite()) {
				request.setAttribute("error", "Cannot unpack " + f.getName()
						+ ", directory is write protected.");
			}
			//GZip
			else if (f.getName().toLowerCase().endsWith(".gz")) {
				//New name is old Name without .gz
				String newName = f.getAbsolutePath().substring(0, f.getAbsolutePath().length() - 3);
				try {
					byte buffer[] = new byte[0xffff];
					copyStreams(new GZIPInputStream(new FileInputStream(f)), new FileOutputStream(
							newName), buffer);
				}
				catch (IOException ex) {
					request.setAttribute("error", "Unpacking of " + f.getName()
							+ " aborted. Error: " + ex);
				}
			}
			//Else try Zip
			else {
				try {
					ZipFile zf = new ZipFile(f);
					Enumeration entries = zf.entries();
					//First check whether a file already exist
					boolean error = false;
					while (entries.hasMoreElements()) {
						ZipEntry entry = (ZipEntry) entries.nextElement();
						if (!entry.isDirectory()
								&& new File(root + File.separator + entry.getName()).exists()) {
							request.setAttribute("error", "Cannot unpack " + f.getName()
									+ ", File " + entry.getName() + " already exists.");
							error = true;
							break;
						}
					}
					if (!error) {
						//Unpack File
						entries = zf.entries();
						byte buffer[] = new byte[0xffff];
						while (entries.hasMoreElements()) {
							ZipEntry entry = (ZipEntry) entries.nextElement();
							File n = new File(root + File.separator + entry.getName());
							if (entry.isDirectory()) n.mkdirs();
							else {
								n.getParentFile().mkdirs();
								n.createNewFile();
								copyStreams(zf.getInputStream(entry), new FileOutputStream(n),
										buffer);
							}
						}
						zf.close();
						request.setAttribute("message", "Unpack of " + f.getName()
								+ " was successful.");
					}
				}
				catch (ZipException ex) {
					request.setAttribute("error", "Cannot unpack " + f.getName()
							+ ", no valid zip file");
				}
				catch (IOException ex) {
					request.setAttribute("error", "Unpacking of " + f.getName()
							+ " aborted. Error: " + ex);
				}
			}
		}
		// Delete Files
		else if ((request.getParameter("Submit") != null)
				&& (request.getParameter("Submit").equals(DELETE_FILES))) {
			Vector v = expandFileList(request.getParameterValues("selfile"), true);
			boolean error = false;
			//delete backwards
			for (int i = v.size() - 1; i >= 0; i--) {
				File f = (File) v.get(i);
                if (!isAllowed(f, true)){
                    request.setAttribute("error", "You are not allowed to access " + f.getAbsolutePath());
                    error = true;
                    break;
                }
				if (!f.canWrite() || !f.delete()) {
					request.setAttribute("error", "Cannot delete " + f.getAbsolutePath()
							+ ". Deletion aborted");
					error = true;
					break;
				}
			}
			if ((!error) && (v.size() > 1)) request.setAttribute("message", "All files deleted");
			else if ((!error) && (v.size() > 0)) request.setAttribute("message", "File deleted");
			else if (!error) request.setAttribute("error", "No files selected");
		}
		// Create Directory
		else if ((request.getParameter("Submit") != null)
				&& (request.getParameter("Submit").equals(CREATE_DIR))) {
			String dir = "" + request.getAttribute("dir");
			String dir_name = request.getParameter("cr_dir");
			String new_dir = getDir(dir, dir_name);
            if (!isAllowed(new File(new_dir), true)){
                request.setAttribute("error", "You are not allowed to access " + new_dir);
            }
			else if (new File(new_dir).mkdirs()) {
				request.setAttribute("message", "Directory created");
			}
			else request.setAttribute("error", "Creation of directory " + new_dir + " failed");
		}
		// Create a new empty file
		else if ((request.getParameter("Submit") != null)
				&& (request.getParameter("Submit").equals(CREATE_FILE))) {
			String dir = "" + request.getAttribute("dir");
			String file_name = request.getParameter("cr_dir");
			String new_file = getDir(dir, file_name);
            if (!isAllowed(new File(new_file), true)){
                request.setAttribute("error", "You are not allowed to access " + new_file);
            }
			// Test, if file_name is empty
			else if (!"".equals(file_name.trim()) && !file_name.endsWith(File.separator)) {
				if (new File(new_file).createNewFile()) request.setAttribute("message",
						"File created");
				else request.setAttribute("error", "Creation of file " + new_file + " failed");
			}
			else request.setAttribute("error", "Error: " + file_name + " is not a valid filename");
		}
		// Rename a file
		else if ((request.getParameter("Submit") != null)
				&& (request.getParameter("Submit").equals(RENAME_FILE))) {
			Vector v = expandFileList(request.getParameterValues("selfile"), true);
			String dir = "" + request.getAttribute("dir");
			String new_file_name = request.getParameter("cr_dir");
			String new_file = getDir(dir, new_file_name);
            if (!isAllowed(new File(new_file), true)){
                request.setAttribute("error", "You are not allowed to access " + new_file);
            }
			// The error conditions:
			// 1) Zero Files selected
			else if (v.size() <= 0) request.setAttribute("error",
					"Select exactly one file or folder. Rename failed");
			// 2a) Multiple files selected and the first isn't a dir
			//     Here we assume that expandFileList builds v from top-bottom, starting with the dirs
			else if ((v.size() > 1) && !(((File) v.get(0)).isDirectory())) request.setAttribute(
					"error", "Select exactly one file or folder. Rename failed");
			// 2b) If there are multiple files from the same directory, rename fails
			else if ((v.size() > 1) && ((File) v.get(0)).isDirectory()
					&& !(((File) v.get(0)).getPath().equals(((File) v.get(1)).getParent()))) {
				request.setAttribute("error", "Select exactly one file or folder. Rename failed");
			}
			else {
				File f = (File) v.get(0);
                if (!isAllowed(f, true)){
                    request.setAttribute("error", "You are not allowed to access " + f.getAbsolutePath());
                }
				// Test, if file_name is empty
				else if ((new_file.trim() != "") && !new_file.endsWith(File.separator)) {
					if (!f.canWrite() || !f.renameTo(new File(new_file.trim()))) {
						request.setAttribute("error", "Creation of file " + new_file + " failed");
					}
					else request.setAttribute("message", "Renamed file "
							+ ((File) v.get(0)).getName() + " to " + new_file);
				}
				else request.setAttribute("error", "Error: \"" + new_file_name
						+ "\" is not a valid filename");
			}
		}
		// Move selected file(s)
		else if ((request.getParameter("Submit") != null)
				&& (request.getParameter("Submit").equals(MOVE_FILES))) {
			Vector v = expandFileList(request.getParameterValues("selfile"), true);
			String dir = "" + request.getAttribute("dir");
			String dir_name = request.getParameter("cr_dir");
			String new_dir = getDir(dir, dir_name);
            if (!isAllowed(new File(new_dir), false)){
                request.setAttribute("error", "You are not allowed to access " + new_dir);
            }
            else{
    			boolean error = false;
                // This ensures that new_dir is a directory
                if (!new_dir.endsWith(File.separator)) new_dir += File.separator;
                for (int i = v.size() - 1; i >= 0; i--) {
                    File f = (File) v.get(i);
                    if (!isAllowed(f, true)){
                        request.setAttribute("error", "You are not allowed to access " + f.getAbsolutePath());
                        error = true;
                        break;
                    }
                    else if (!f.canWrite() || !f.renameTo(new File(new_dir
                            + f.getAbsolutePath().substring(dir.length())))) {
                        request.setAttribute("error", "Cannot move " + f.getAbsolutePath()
                                + ". Move aborted");
                        error = true;
                        break;
                    }
                }
                if ((!error) && (v.size() > 1)) request.setAttribute("message", "All files moved");
                else if ((!error) && (v.size() > 0)) request.setAttribute("message", "File moved");
                else if (!error) request.setAttribute("error", "No files selected");
            }
		}
		// Copy Files
		else if ((request.getParameter("Submit") != null)
				&& (request.getParameter("Submit").equals(COPY_FILES))) {
			Vector v = expandFileList(request.getParameterValues("selfile"), true);
			String dir = (String) request.getAttribute("dir");
			if (!dir.endsWith(File.separator)) dir += File.separator;
			String dir_name = request.getParameter("cr_dir");
			String new_dir = getDir(dir, dir_name);
            if (!isAllowed(new File(new_dir), true)){
                request.setAttribute("error", "You are not allowed to access " + new_dir);
            }
            else{
    			boolean error = false;
                if (!new_dir.endsWith(File.separator)) new_dir += File.separator;
                try {
                    byte buffer[] = new byte[0xffff];
                    for (int i = 0; i < v.size(); i++) {
                        File f_old = (File) v.get(i);
                        File f_new = new File(new_dir + f_old.getAbsolutePath().substring(dir.length()));
                        if (!isAllowed(f_old, false)|| !isAllowed(f_new, true)){
                            request.setAttribute("error", "You are not allowed to access " + f_new.getAbsolutePath());
                            error = true;
                        }
                        else if (f_old.isDirectory()) f_new.mkdirs();
                        // Overwriting is forbidden
                        else if (!f_new.exists()) {
                            copyStreams(new FileInputStream(f_old), new FileOutputStream(f_new), buffer);
                        }
                        else {
                            // File exists
                            request.setAttribute("error", "Cannot copy " + f_old.getAbsolutePath()
                                    + ", file already exists. Copying aborted");
                            error = true;
                            break;
                        }
                    }
                }
                catch (IOException e) {
                    request.setAttribute("error", "Error " + e + ". Copying aborted");
                    error = true;
                }
                if ((!error) && (v.size() > 1)) request.setAttribute("message", "All files copied");
                else if ((!error) && (v.size() > 0)) request.setAttribute("message", "File copied");
                else if (!error) request.setAttribute("error", "No files selected");
            }
		}
		// Directory viewer
		if (dir_view && request.getAttribute("dir") != null) {
			File f = new File("" + request.getAttribute("dir"));
			//Check, whether the dir exists
			if (!f.exists() || !isAllowed(f, false)) {
				if (!f.exists()){
                    request.setAttribute("error", "Directory " + f.getAbsolutePath() + " does not exist.");
                }
                else{
                    request.setAttribute("error", "You are not allowed to access " + f.getAbsolutePath());
                }
				//if attribute olddir exists, it will change to olddir
				if (request.getAttribute("olddir") != null && isAllowed(new File((String) request.getAttribute("olddir")), false)) {
					f = new File("" + request.getAttribute("olddir"));
				}
				//try to go to the parent dir
				else {
					if (f.getParent() != null && isAllowed(f, false)) f = new File(f.getParent());
				}
				//If this dir also do also not exist, go back to browser.jsp root path
				if (!f.exists()) {
					String path = null;
					if (application.getRealPath(request.getRequestURI()) != null) path = new File(
							application.getRealPath(request.getRequestURI())).getParent();

					if (path == null) // handle the case were we are not in a directory (ex: war file)
					path = new File(".").getAbsolutePath();
					f = new File(path);
				}
				if (isAllowed(f, false)) request.setAttribute("dir", f.getAbsolutePath());
                else request.setAttribute("dir", null);
			}
%>
<script type="text/javascript" src="<%=browser_name %>?Javascript">
</script>
<link type="text/css" rel="stylesheet"  href="../css/styles_ceso.css"/>
<link type="text/css" rel="stylesheet" href="../css/ticker/simpleTicker.css" />
<link type="text/css" rel="stylesheet" href="../css/dropdown/dropdown.css" media="screen" />
<link type="text/css" rel="stylesheet" href="../css/dropdown/default.advanced.css" media="screen" />
<link type="text/css" rel="stylesheet" href="../css/form.css"  media="screen"/>
<link type="text/css" rel="stylesheet" href="../css/jquery.jnotify-alt.css" media="all" />
<link type="text/css" rel="stylesheet" href="../css/jqModal.css" />
<link type="text/css" rel="stylesheet" href="../css/common.css" />
<link type="text/css" rel="stylesheet" href="../css/redmond/jquery-ui-1.8.14.custom.css" />
<link type="text/css" rel="stylesheet" href="../css/ui.multiselect.css"  />

<title><%=request.getAttribute("dir")%></title>
</head>
<body>
            <div id="container">
            <div id="header">
                <div id="bkorotator">
                    <img alt="" src="../images/rotator/1.jpg" />
                </div>
            </div>
            <div id="menu">
                <%@include file="../menu.jsp" %>
            </div>
            <div id="content">
<%
			//Output message
			if (request.getAttribute("message") != null) {
				out.println("<table border=\"0\" width=\"100%\"><tr><td class=\"message\">");
				out.println(request.getAttribute("message"));
				out.println("</td></tr></table>");
			}
			//Output error
			if (request.getAttribute("error") != null) {
				out.println("<table border=\"0\" width=\"100%\"><tr><td class=\"error\">");
				out.println(request.getAttribute("error"));
				out.println("</td></tr></table>");
			}
            if (request.getAttribute("dir") != null){
%>

	<form class="formular" action="<%= browser_name %>" method="Post" name="FileList">
    Filename filter: <input name="filt" onKeypress="event.cancelBubble=true;" onkeyup="filter(this)" type="text">
    <br /><br />
	<table id="filetable" class="filelist" cellspacing="1px" cellpadding="0px">
<%
			// Output the table, starting with the headers.
			String dir = URLEncoder.encode("" + request.getAttribute("dir"));
			String cmd = browser_name + "?dir=" + dir;

			int sortMode = 1;
			if (request.getParameter("sort") != null) sortMode = Integer.parseInt(request
					.getParameter("sort"));
			int[] sort = new int[] {1, 2, 3, 4};
			for (int i = 0; i < sort.length; i++)
				if (sort[i] == sortMode) sort[i] = -sort[i];
			out.print("<tr><th>&nbsp;</th><th title=\"Sort files by name\" align=left><a href=\""
					+ cmd + "&amp;sort=" + sort[0] + "\">Name</a></th>"
					+ "<th title=\"Sort files by size\" align=\"right\"><a href=\"" + cmd
					+ "&amp;sort=" + sort[1] + "\">Size</a></th>"
					+ "<th title=\"Sort files by type\" align=\"center\"><a href=\"" + cmd
					+ "&amp;sort=" + sort[3] + "\">Type</a></th>"
					+ "<th title=\"Sort files by date\" align=\"left\"><a href=\"" + cmd
					+ "&amp;sort=" + sort[2] + "\">Date</a></th>"
					+ "<th>&nbsp;</th>");
			if (!READ_ONLY) out.print ("<th>&nbsp;</th>");
			out.println("</tr>");
			char trenner = File.separatorChar;
			// Output the Root-Dirs, without FORBIDDEN_DRIVES
			File[] entry = File.listRoots();
			for (int i = 0; i < entry.length; i++) {
				boolean forbidden = false;
				for (int i2 = 0; i2 < FORBIDDEN_DRIVES.length; i2++) {
					if (entry[i].getAbsolutePath().toLowerCase().equals(FORBIDDEN_DRIVES[i2])) forbidden = true;
				}
				if (!forbidden) {
					out.println("<tr class=\"mouseout\" onmouseover=\"this.className='mousein'\""
							+ "onmouseout=\"this.className='mouseout'\">");
					out.println("<td>&nbsp;</td><td align=left >");
					String name = URLEncoder.encode(entry[i].getAbsolutePath());
					String buf = entry[i].getAbsolutePath();
					out.println(" &nbsp;<a href=\"" + browser_name + "?sort=" + sortMode
							+ "&amp;dir=" + name + "\">[" + buf + "]</a>");
					out.print("</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td></td></tr>");
				}
			}
			// Output the parent directory link ".."
			if (f.getParent() != null) {
				out.println("<tr class=\"mouseout\" onmouseover=\"this.className='mousein'\""
						+ "onmouseout=\"this.className='mouseout'\">");
				out.println("<td></td><td align=left>");
				out.println(" &nbsp;<a href=\"" + browser_name + "?sort=" + sortMode + "&amp;dir="
						+ URLEncoder.encode(f.getParent()) + "\">" + FOL_IMG + "[..]</a>");
				out.print("</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td></td></tr>");
			}
			// Output all files and dirs and calculate the number of files and total size
			entry = f.listFiles();
			if (entry == null) entry = new File[] {};
			long totalSize = 0; // The total size of the files in the current directory
			long fileCount = 0; // The count of files in the current working directory
			if (entry != null && entry.length > 0) {
				Arrays.sort(entry, new FileComp(sortMode));
				for (int i = 0; i < entry.length; i++) {
					String name = URLEncoder.encode(entry[i].getAbsolutePath());
					String type = "File"; // This String will tell the extension of the file
					if (entry[i].isDirectory()) type = "DIR"; // It's a DIR
					else {
						String tempName = entry[i].getName().replace(' ', '_');
						if (tempName.lastIndexOf('.') != -1) type = tempName.substring(
								tempName.lastIndexOf('.')).toLowerCase();
					}
					String ahref = "<a onmousedown=\"dis()\" href=\"" + browser_name + "?sort="
							+ sortMode + "&amp;";
					String dlink = "&nbsp;"; // The "Download" link
					String elink = "&nbsp;"; // The "Edit" link
					String buf = conv2Html(entry[i].getName());
					if (!entry[i].canWrite()) buf = "<i>" + buf + "</i>";
					String link = buf; // The standard view link, uses Mime-type
					if (entry[i].isDirectory()) {
						if (entry[i].canRead() && USE_DIR_PREVIEW) {
							//Show the first DIR_PREVIEW_NUMBER directory entries in a tooltip
							File[] fs = entry[i].listFiles();
							if (fs == null) fs = new File[] {};
							Arrays.sort(fs, new FileComp());
							StringBuffer filenames = new StringBuffer();
							for (int i2 = 0; (i2 < fs.length) && (i2 < 10); i2++) {
								String fname = conv2Html(fs[i2].getName());
								if (fs[i2].isDirectory()) filenames.append("[" + fname + "];");
								else filenames.append(fname + ";");
							}
							if (fs.length > DIR_PREVIEW_NUMBER) filenames.append("...");
							else if (filenames.length() > 0) filenames
									.setLength(filenames.length() - 1);
							link = ahref + "dir=" + name + "\" title=\"" + filenames + "\">"
									+ FOL_IMG + "[" + buf + "]</a>";
						}
						else if (entry[i].canRead()) {
							link = ahref + "dir=" + name + "\">" + FOL_IMG + "[" + buf + "]</a>";
						}
						else link = FOL_IMG + "[" + buf + "]";
					}
					else if (entry[i].isFile()) { //Entry is file
						totalSize = totalSize + entry[i].length();
						fileCount = fileCount + 1;
						if (entry[i].canRead()) {
							dlink = ahref + "downfile=" + name + "\">Download</a>";
							//If you click at the filename
							if (USE_POPUP) link = ahref + "file=" + name + "\" target=\"_blank\">"
									+ buf + "</a>";
							else link = ahref + "file=" + name + "\">" + buf + "</a>";
							if (entry[i].canWrite()) { // The file can be edited
								//If it is a zip or jar File you can unpack it
								if (isPacked(name, true)) elink = ahref + "unpackfile=" + name
										+ "\">Unpack</a>";
								else elink = ahref + "editfile=" + name + "\">Edit</a>";
							}
							else { // If the file cannot be edited
								//If it is a zip or jar File you can unpack it
								if (isPacked(name, true)) elink = ahref + "unpackfile=" + name
										+ "\">Unpack</a>";
								else elink = ahref + "editfile=" + name + "\">View</a>";
							}
						}
						else {
							link = buf;
						}
					}
					String date = dateFormat.format(new Date(entry[i].lastModified()));
					out.println("<tr class=\"mouseout\" onmouseup=\"selrow(this, 2)\" "
							+ "onmouseover=\"selrow(this, 0);\" onmouseout=\"selrow(this, 1)\">");
					if (entry[i].canRead()) {
						out.println("<td align=center><input type=\"checkbox\" name=\"selfile\" value=\""
										+ name + "\" onmousedown=\"dis()\"></td>");
					}
					else {
						out.println("<td align=center><input type=\"checkbox\" name=\"selfile\" disabled></td>");
					}
					out.print("<td align=left> &nbsp;" + link + "</td>");
					if (entry[i].isDirectory()) out.print("<td>&nbsp;</td>");
					else {
						out.print("<td align=right title=\"" + entry[i].length() + " bytes\">"
								+ convertFileSize(entry[i].length()) + "</td>");
					}
					out.println("<td align=\"center\">" + type + "</td><td align=left> &nbsp;" + // The file type (extension)
							date + "</td><td>" + // The date the file was created
							dlink + "</td>"); // The download link
					if (!READ_ONLY)
						out.print ("<td>" + elink + "</td>"); // The edit link (or view, depending)
					out.println("</tr>");
				}
			}%>
	</table>
	<input type="checkbox" name="selall" onClick="AllFiles(this.form)">Select all
	<p align=center>
		<b title="<%=totalSize%> bytes">
		<%=convertFileSize(totalSize)%></b><b> in <%=fileCount%> files in <%= dir2linkdir((String) request.getAttribute("dir"), browser_name, sortMode)%>
		</b>
	</p>
		<input type="hidden" name="dir" value="<%=request.getAttribute("dir")%>">
		<input type="hidden" name="sort" value="<%=sortMode%>">
		<input title="Download selected files and directories as one zip file" class="button" id="but_Zip" type="Submit" name="Submit" value="<%=SAVE_AS_ZIP%>">
		<% if (!READ_ONLY) {%>
			<input title="Delete all selected files and directories incl. subdirs" class="button"  id="but_Del" type="Submit" name="Submit" value="<%=DELETE_FILES%>"
			onclick="return confirm('Do you really want to delete the entries?')">
		<% } %>
	<% if (!READ_ONLY) {%>
	<br />
		<input title="Enter new dir or filename or the relative or absolute path" class="textfield" type="text" onKeypress="event.cancelBubble=true;" id="text_Dir" name="cr_dir">
		<input title="Create a new directory with the given name" class="button" id="but_NDi" type="Submit" name="Submit" value="<%=CREATE_DIR%>">
		<input title="Create a new empty file with the given name" class="button" id="but_NFi" type="Submit" name="Submit" value="<%=CREATE_FILE%>">
		<input title="Move selected files and directories to the entered path" id="but_Mov" class="button" type="Submit" name="Submit" value="<%=MOVE_FILES%>">
		<input title="Copy selected files and directories to the entered path" id="but_Cop" class="button" type="Submit" name="Submit" value="<%=COPY_FILES%>">
		<input title="Rename selected file or directory to the entered name" id="but_Ren" class="button" type="Submit" name="Submit" value="<%=RENAME_FILE%>">
	<% } %>
	</form>
	<br />
	<div class="formular">
	<% if (ALLOW_UPLOAD) { %>
	<form class="formular2" action="<%= browser_name%>" enctype="multipart/form-data" method="POST">
		<input type="hidden" name="dir" value="<%=request.getAttribute("dir")%>">
		<input type="hidden" name="sort" value="<%=sortMode%>">
		<input type="file" class="textfield" onKeypress="event.cancelBubble=true;" name="myFile">
		<input title="Upload selected file to the current working directory" type="Submit" class="button" name="Submit" value="<%=UPLOAD_FILES%>"
		onClick="javascript:popUp('<%= browser_name%>')">
	</form>
	<%} %>
	<% if (NATIVE_COMMANDS) {%>
    <form class="formular2" action="<%= browser_name%>" method="POST">
		<input type="hidden" name="dir" value="<%=request.getAttribute("dir")%>">
		<input type="hidden" name="sort" value="<%=sortMode%>">
		<input type="hidden" name="command" value="">
		<input title="Launch command in current directory" type="Submit" class="button" id="but_Lau" name="Submit" value="<%=LAUNCH_COMMAND%>">
	</form><%
    }%>
    </div>
    <%}%>
	<hr>
	<center>
		<small>jsp File Browser version <%= VERSION_NR%> by <a href="http://www.vonloesch.de">www.vonloesch.de</a></small>
	</center>
        <%@include file="../footer.jsp" %>
</body>
</html><%
    }
%>
