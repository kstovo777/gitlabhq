/* global Api */

import TemplateSelector from './template_selector';

export default class BlobGitignoreSelector extends TemplateSelector {
  requestFile(query) {
    return Api.gitignoreText(query.name, this.requestFileSuccess.bind(this));
  }
}
