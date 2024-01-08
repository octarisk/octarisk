%# Copyright (C) 2023 Stefan Schlögl <schinzilord@octarisk.com>
%#
%# This program is free software; you can redistribute it and/or modify it under
%# the terms of the GNU General Public License as published by the Free Software
%# Foundation; either version 3 of the License, or (at your option) any later
%# version.
%#
%# This program is distributed in the hope that it will be useful, but WITHOUT
%# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
%# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
%# details.
%#
%# You should have received a copy of the GNU General Public License along with
%# this program; if not, see <http://www.gnu.org/licenses/>.
 
%# -*- texinfo -*-
%# @deftypefn {Function File} {[@var{retcode} ] =} export_to_redis(@var{para},@var{instrument_struct},@var{index_struct},@var{port_obj_struct})
%# Exports instruments, index and portfolio objects to a Redis database using go-redis library for Octave (https://github.com/markuman/go-redis).
%# All objects are exported as JSON and can be loaded by other programs (e.g. with Python).
%# @end deftypefn

function ret = export_to_redis(para,instrument_struct,index_struct,port_obj_struct)

export_flag = para.get('export_to_redis_db');
fprintf('Exporting to redis database.\n');

% determin shred type and cvar_type
shred_type = para.get('shred_type');
if (strcmpi(shred_type,'TOTAL') || strcmpi(shred_type,'EQ') || strcmpi(shred_type,'IR'))
	fprintf('Shred type equals TOTAL, IR or EQ. Export to db.\n');
	export_flag = 1;
else
    fprintf('Shred type not TOTAL, IR or EQ. No export to db.\n');
	export_flag = 0;
end
	
if (export_flag == 1)
	ip = para.get('redis_ip');
	port = para.get('redis_port');
	dbnr = para.get('redis_dbnr');
	shred = strcat(toupper(para.get('cvar_type')),'_',toupper(shred_type));
	
	fprintf('Exporting to database %s for shred type %s.\n',ip,shred);
	pong = '';
	try
		r = redis('hostname', ip,'port', port,'dbnr',dbnr);
		pong = r.ping;
	catch
		fprintf('WARN: Database connection not established to >>%s<< on port >>%s<< with database >>%s<<. Skipping export.\n',any2str(ip),any2str(port),any2str(dbnr));
		ret = 0;
	end
	if strcmpi(pong,'PONG')
		fprintf('Database connection successfully established to >>%s<< on port >>%s<< with database >>%s<<.\n',any2str(ip),any2str(port),any2str(dbnr));
		try
			for kk = 1:1:length(instrument_struct)
				obj = instrument_struct(kk).object;
				if (isobject(obj))
					JSON_text = jsonencode(obj);
					fprintf('Exporting instrument >>%s<< to database.\n',obj.id);
					tmp_id = strcat(shred,'_INSTR_',obj.id);
					ret = r.set(tmp_id,JSON_text);
					fprintf('Ret code of operation >>%s<<.\n',ret);
				end
			end
			for kk = 1:1:length(index_struct)
				obj = index_struct(kk).object;
				if (isobject(obj))
					JSON_text = jsonencode(obj);
					fprintf('Exporting index object >>%s<< to database.\n',obj.id);
					tmp_id = strcat(shred,'_INDEX_',obj.id);
					ret = r.set(tmp_id,JSON_text);
					fprintf('Ret code of operation >>%s<<.\n',ret);
				end
			end
			
			for kk = 1:1:length(port_obj_struct)
				obj = port_obj_struct(kk).object;
				if (isobject(obj))
					JSON_text = jsonencode(obj);
					fprintf('Exporting portfolio >>%s<< to database.\n',obj.id);
					tmp_id = strcat(shred,'_PORT_',obj.id);
					ret = r.set(tmp_id,JSON_text);
					fprintf('Ret code of operation >>%s<<.\n',ret);
				end
			end
			
			JSON_text = jsonencode(para);
			fprintf('Exporting Parameter to database.\n');
			ret = r.set(strcat(shred,'_PARAMETER'),JSON_text);
			fprintf('Ret code of operation >>%s<<.\n',ret);
			
		catch   
			fprintf('There was an error: %s\n',lasterr);
		end
		ret = 1;
	else
		fprintf('WARN: Database connection not established to >>%s<< on port >>%s<< with database >>%s<<. Skipping export.\n',any2str(ip),any2str(port),any2str(dbnr));
		ret = 0;
	end
else
	fprintf('Export flag is false. No Exporting to redis database.\n');
	ret = 0;
end


end % end function

%!test 
%! fprintf('\tTesting export to redis script:\n');
%! para = Parameter();
%! para = para.set('export_to_redis_db',0);
%! ret = export_to_redis(para,Instrument(),Index(),Position());
%! assert(ret,0)

%!test 
%! fprintf('\tTesting export to redis script:\n');
%! para = Parameter();
%! para = para.set('redis_ip','192.168.0.1');
%! para = para.set('export_to_redis_db',1);
%! ret = export_to_redis(para,Instrument(),Index(),Position());
%! assert(ret,0)
