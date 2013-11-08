<!DOCTYPE html>
<html>
<head>
	<meta http-equiv="expires" content="-1"/>
	<meta http-equiv="content-type" content="text/html; charset=utf-8"/>
	<meta name="copyright" content="2013, Web Site Management" />
	<meta http-equiv="X-UA-Compatible" content="IE=edge" >
	<title>TagIt</title>
	<style type="text/css">
		body
		{
			padding-top: 60px;
		}
	</style>
	<link rel="stylesheet" href="css/bootstrap.min.css" />
	<style type="text/css">
		.category, .keywords
		{
			margin-bottom: 0px;
			padding-right: 15px;
		}
		.keywords
		{
			padding: 10px 15px 0px 15px;
		}
		.keyword.selected
		{
			background-color: red;
		}
		#categorieskeywordsarea
		{
			display: none;
		}
	</style>
	<script type="text/javascript" src="js/jquery-1.10.2.min.js"></script>
	<script type="text/javascript" src="js/bootstrap.min.js"></script>
	<script type="text/javascript" src="js/handlebars.js"></script>
	<script type="text/javascript" src="rqlconnector/Rqlconnector.js"></script>
	<script id="categories-template" type="text/x-handlebars-template">
		<ul class="thumbnails categories">
		</ul>
	</script>
	<script id="category-template" type="text/x-handlebars-template">
		<li class="span4">
			<div class="thumbnail" id="{{guid}}">
				<div class="alert alert-info category form-inline">
					<label class="checkbox">
						<input type="checkbox"> {{name}}
					</label>
				</div>
				<div class="keywords">
				</div>
			</div>
		</li>
	</script>
	<script id="keyword-template" type="text/x-handlebars-template">
		<div class="keyword">
			<label class="checkbox">
				<input type="checkbox" id="{{guid}}"> {{name}}
			</label>
		</div>
	</script>
	<script id="pagekeyword-template" type="text/x-handlebars-template">
		<div id="pagekeywords{{guid}}">{{guid}}</div>
	</script>
	<script id="pagecategory-template" type="text/x-handlebars-template">
		<div id="pagecategory{{guid}}">{{guid}}</div>
	</script>
	<script type="text/javascript">
		var _PageGuid = '<%= session("treeguid") %>';
		var LoginGuid = '<%= session("loginguid") %>';
		var SessionKey = '<%= session("sessionkey") %>';
		var RqlConnectorObj = new RqlConnector(LoginGuid, SessionKey);
	
		$( document ).ready(function() {
			Init();

			LoadPageCategoryKeyword(_PageGuid);
		});
		
		function InitPageGuid()
		{
			var objClipBoard = window.opener.document;
			var SmartEditURL;
			if($(objClipBoard).find('iframe[name=Preview]').length > 0)
			{
				SmartEditURL = $(objClipBoard).find('iframe[name=Preview]').contents().get(0).location;
			}
			
			var EditPageGuid = GetUrlVars(SmartEditURL)['EditPageGUID'];
			var ParamPageGuid = GetUrlVars()['pageguid'];
			
			if(EditPageGuid != null)
			{
				_PageGuid = EditPageGuid;
			}
			else if (ParamPageGuid != null)
			{
				_PageGuid = ParamPageGuid;
			}
		}
		
		function GetUrlVars(SourceUrl)
		{
			if(SourceUrl == undefined)
			{
				SourceUrl = window.location.href;
			}
			SourceUrl = new String(SourceUrl);
			var vars = [], hash;
			var hashes = SourceUrl.slice(SourceUrl.indexOf('?') + 1).split('&');
			for(var i = 0; i < hashes.length; i++)
			{
				hash = hashes[i].split('=');
				vars.push(hash[0]);
				vars[hash[0]] = hash[1];
			}
	
			return vars;
		}
		
		function Init()
		{
			InitPageGuid();

			$('#main').on('change', '.category input:checkbox', function() {
				if($(this).is(':checked'))
				{
					$(this).parents('.category').siblings('.keywords').find('.keyword input:checkbox').prop('checked', true);
				}
				else
				{
					$(this).parents('.category').siblings('.keywords').find('.keyword input:checkbox').prop('checked', false);
				}
				
				$(this).parents('.category').siblings('.keywords').find('.keyword input:checkbox').trigger('change');
			});

			$('#main').on('change', '.keyword input:checkbox', function(){
				if($(this).is(':checked'))
				{
					$(this).parents('.keyword').addClass('alert-success');

					$(this).parents('.keywords').siblings('.category').find('input:checkbox').prop('checked', true);
				}
				else
				{
					$(this).parents('.keyword').removeClass('alert-success');
					
					// uncheck category if all keywords are unchecked
					if($(this).parents('.keywords').find('input:checked').length == 0)
					{
						$(this).parents('.keywords').siblings('.category').find('input:checkbox').prop('checked', false);
					}
				}
			});
		}
		
		function LoadCategories()
		{
			var strRQLXML = '<PROJECT><CATEGORIES action="list"/></PROJECT>';
			
			// send RQL XML
			RqlConnectorObj.SendRql(strRQLXML, false, function(data){
				// create display areas for each category
				$(data).find('CATEGORY').each(function(){
					var CategoryGuid = $(this).attr('guid');
					var CategoryName = $(this).attr('value');
					AddCategory(CategoryGuid, CategoryName);
					
					LoadKeywords(CategoryGuid);
				});
			});
		}
		
		function LoadKeywords(CategoryGuid)
		{
			var strRQLXML = '<PROJECT><CATEGORY guid="' + CategoryGuid + '"><KEYWORDS action="load"/></CATEGORY></PROJECT>';
			
			// send RQL XML
			RqlConnectorObj.SendRql(strRQLXML, false, function(data){
				var TargetArea = '#' + CategoryGuid + 'area .content';
			
				$(TargetArea).empty();
			
				// create display areas for each category
				$(data).find('KEYWORD[guid!=' + CategoryGuid + ']').each(function(){
					var KeywordGuid = $(this).attr('guid');
					var KeywordName = $(this).attr('value');
					
					AddKeyword(CategoryGuid, KeywordGuid, KeywordName);
					
					CheckCategoryKeywordUsage(KeywordGuid);
				});
			});
		}
		
		function CheckCategoryKeywordUsage(KeywordGuid)
		{
			if($('#pagekeywords' + KeywordGuid).length > 0)
			{
				$('#' + KeywordGuid).trigger('click');
			}
		}
		
		function LoadPageCategoryKeyword(PageGuid)
		{
			var strRQLXML = '<PROJECT><PAGE guid="' + PageGuid + '"><KEYWORDS action="load"/></PAGE></PROJECT>';
			
			// send RQL XML
			RqlConnectorObj.SendRql(strRQLXML, false, function(data){
				$(data).find('KEYWORD').each(function(){
					var PageKeywordGuid = $(this).attr('guid');
					var PageKeywordName = $(this).attr('value');
					
					if(PageKeywordName == '[category]')
					{
						AddPageCategory(PageKeywordGuid);
					}
					else
					{
						AddPageKeyword(PageKeywordGuid);
					}
				});
			});
			
			LoadCategories();
		}
		
		function Save(PageGuid)
		{
			$('#saving').modal('show');
		
			// check which keyword should be flagged as deleted
			$('#pagekeywords div').each(function(){
				var KeywordGuid = $(this).text();

				if(!$('#' + KeywordGuid).is(':checked'))
				{
					$('#tobedeletedcategorykeywords').append($(this));
				}
			});
			
			// check which keyword should be flagged as added
			$('.keyword input:checkbox:checked').each(function(){
				if($('#pagekeywords' + $(this).attr('id')).length == 0)
				{
					$('#tobaddedcategorykeywords').append('<div>' + $(this).attr('id') + '</div>');
				}
			});
			
			var AssignCategoryKeywordRQL = '';
			
			AssignCategoryKeywordRQL += '<PROJECT>';
			AssignCategoryKeywordRQL += '<PAGE guid="' + PageGuid + '" action="assign">';
			AssignCategoryKeywordRQL += '<KEYWORDS>';
			
			$('#pagecategories div').each(function(){
				AssignCategoryKeywordRQL += '<KEYWORD guid="' + $(this).text() + '" changed="0" />';
			});
			
			$('#pagekeywords div').each(function(){
				AssignCategoryKeywordRQL += '<KEYWORD guid="' + $(this).text() + '" changed="0" />';
			});
			
			$('#tobedeletedcategorykeywords div').each(function(){
				AssignCategoryKeywordRQL += '<KEYWORD guid="' + $(this).text() + '" delete="1" changed="1" />';
			});
			
			$('#tobaddedcategorykeywords div').each(function(){
				AssignCategoryKeywordRQL += '<KEYWORD guid="' + $(this).text() + '" changed="1" />';
			});
			
			AssignCategoryKeywordRQL += '</KEYWORDS>';
			AssignCategoryKeywordRQL += '</PAGE>';
			AssignCategoryKeywordRQL += '</PROJECT>';
			
			var strRQLXML = AssignCategoryKeywordRQL;
			
			// send RQL XML
			RqlConnectorObj.SendRql(strRQLXML, false, function(data){
				$('#saving').modal('hide');
				
				Close(true);
			});
		}
		
		function Close(Refresh)
		{
			if(Refresh)
			{
				if (window.opener.name == 'ioTop')
				{
					// Launched from SmartEdit Mode Toolbar
					window.opener.ReloadEditedPage();
				}
				else if (window.opener.name == 'ioMain')
				{
					// Launched from Custom RedDot
					window.opener.location.reload();
				}
				else if (window.opener.name == 'Preview')
				{
					// Launched from Custom RedDot
					window.opener.location.reload();
				}
				else if (window.opener.ReloadTreeSegment!=null)
				{
					// Launched from SmartTree
					window.opener.ReloadTreeSegment();
				}
			}
		
			window.opener = '';
			self.close();
		}
		
		function AddPageKeyword(KeywordGuid)
		{
			var KeywordObject = new Object();
			KeywordObject.guid = KeywordGuid;
			
			var source = $("#pagekeyword-template").html();
			var template = Handlebars.compile(source);
			var html = template(KeywordObject);
			$('#pagekeywords').append(html);
		}
		function AddPageCategory(CategoryGuid)
		{
			var CategoryObject = new Object();
			CategoryObject.guid = CategoryGuid;
			
			var source = $("#pagecategory-template").html();
			var template = Handlebars.compile(source);
			var html = template(CategoryObject);
			$('#pagecategories').append(html);
		}
		
		function AddCategory(CategoryGuid, CategoryName)
		{
			var AvailableCategoriesSection = GetCategoriesSection();
		
			var CategoryObject = new Object();
			CategoryObject.name = CategoryName;
			CategoryObject.guid = CategoryGuid;
			
			var source = $("#category-template").html();
			var template = Handlebars.compile(source);
			var html = template(CategoryObject);
			$(AvailableCategoriesSection).append(html);
		}
		
		function AddKeyword(CategoryGuid, KeywordGuid, KeywordName)
		{
			var KeywordObject = new Object();
			KeywordObject.name = KeywordName;
			KeywordObject.guid = KeywordGuid;
			
			var source = $("#keyword-template").html();
			var template = Handlebars.compile(source);
			var html = template(KeywordObject);
			$('#' + CategoryGuid + ' .keywords').append(html);
		}
		
		function GetCategoriesSection()
		{
			var LastCategoriesSection = $('.categories:last');
			
			if($(LastCategoriesSection).length == 0)
			{
				CreateCategoriesSection();
			}
			
			LastCategoriesSection = $('.categories:last');

			if($(LastCategoriesSection).find('.category').length >= 3)
			{
				CreateCategoriesSection();
			}
			
			LastCategoriesSection = $('.categories:last');
			return LastCategoriesSection;
		}
		
		function CreateCategoriesSection()
		{
			var source = $("#categories-template").html();
			var template = Handlebars.compile(source);
			var html = template();
			$('#main').append(html);
		}
	</script>
</head>
<body>
	<div class="navbar navbar-inverse navbar-fixed-top">
		<div class="navbar-inner">
			<div class="container">
				<div class="pull-right">
					<button class="btn" type="button" onclick="Close(false);">Close</button>
					<button class="btn btn-success" href="#" onclick="Save(_PageGuid);"><i class="icon-plus-sign icon-white"></i> Save</button>
				</div>
			</div>
		</div>
	</div>
	<div class="container" id="main">

	</div>
	<div id="saving" class="modal hide fade" data-backdrop="static" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
		<div class="modal-header">
			<h3>Saving</h3>
		</div>
		<div class="modal-body">
			<p>Please wait...</p>
		</div>
	</div>
	<div id="categorieskeywordsarea">
		<div id="pagekeywords"></div>
		<div id="pagecategories"></div>
		<div id="tobedeletedcategorykeywords"></div>
		<div id="tobaddedcategorykeywords"></div>
	</div>
</body>
</html>